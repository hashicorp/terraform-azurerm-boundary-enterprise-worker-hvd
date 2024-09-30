#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/boundary-cloud-init.log"
SYSTEMD_DIR="${systemd_dir}"
BOUNDARY_DIR_CONFIG="${boundary_dir_config}"
BOUNDARY_CONFIG_PATH="$BOUNDARY_DIR_CONFIG/worker.hcl"
BOUNDARY_DIR_DATA="${boundary_dir_home}/data"
BOUNDARY_DIR_LOGS="/var/log/boundary"
BOUNDARY_DIR_BIN="${boundary_dir_bin}"
BOUNDARY_USER="boundary"
BOUNDARY_GROUP="boundary"
BOUNDARY_INSTALL_URL="${boundary_install_url}"
REQUIRED_PACKAGES="jq unzip"
ADDITIONAL_PACKAGES="${additional_package_names}"

function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"

  echo "$log_entry" | tee -a "$LOGFILE"
}

function detect_os_distro {
  local OS_DISTRO_NAME=$(grep "^NAME=" /etc/os-release | cut -d"\"" -f2)
  local OS_DISTRO_DETECTED

  case "$OS_DISTRO_NAME" in
  "Ubuntu"*)
    OS_DISTRO_DETECTED="ubuntu"
    ;;
  "CentOS Linux"*)
    OS_DISTRO_DETECTED="centos"
    ;;
  "Red Hat"*)
    OS_DISTRO_DETECTED="rhel"
    ;;
  *)
    log "ERROR" "'$OS_DISTRO_NAME' is not a supported Linux OS distro for Boundary."
    exit_script 1
    ;;
  esac

  echo "$OS_DISTRO_DETECTED"
}

function install_prereqs {
  local OS_DISTRO="$1"
  log "INFO" "Installing required packages..."

  if [[ "$OS_DISTRO" == "ubuntu" ]]; then
    apt-get update -y
    apt-get install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  elif [[ "$OS_DISTRO" == "rhel" ]]; then
    yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
  else
    log "ERROR" "Unsupported OS distro '$OS_DISTRO'. Exiting."
    exit_script 1
  fi
}

function install_azcli() {
  local OS_DISTRO="$1"

  if [[ -n "$(command -v az)" ]]; then
    log "INFO" "Detected 'az' (azure-cli) is already installed. Skipping."
  else
    if [[ "$OS_DISTRO" == "ubuntu" ]]; then
      log "INFO" "Installing Azure CLI for Ubuntu."
      curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    elif [[ "$OS_DISTRO" == "centos" ]] || [[ "$OS_DISTRO" == "rhel" ]]; then
      log "INFO" "Installing Azure CLI for CentOS/RHEL."
      rpm --import https://packages.microsoft.com/keys/microsoft.asc
      cat >/etc/yum.repos.d/azure-cli.repo <<EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
      dnf install -y azure-cli
    fi
  fi
}

function scrape_vm_info {
  log "INFO" "Scraping VM metadata for private IP address..."
  VM_PRIVATE_IP=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2021-02-01&format=text")
  VM_PUBLIC_IP=$(curl -s -H Metadata:true "http://169.254.169.254:80/metadata/loadbalancer?api-version=2020-10-01" | jq -r '.loadbalancer.publicIpAddresses[0].frontendIpAddress')
  log "INFO" "Detected VM private IP address is '$VM_PRIVATE_IP'."
}

# user_create creates a dedicated linux user for Boundary
function user_group_create {
  log "INFO" "Creating Boundary user and group..."

  # Create the dedicated as a system group
  sudo groupadd --system $BOUNDARY_GROUP

  # Create a dedicated user as a system user
  sudo useradd --system --no-create-home -d $BOUNDARY_DIR_CONFIG -g $BOUNDARY_GROUP $BOUNDARY_USER

  log "INFO" "Done creating Boundary user and group"
}

function directory_create {
  log "INFO" "Creating necessary directories..."

  # Define all directories needed as an array
  directories=($BOUNDARY_DIR_CONFIG $BOUNDARY_DIR_DATA $BOUNDARY_DIR_LOGS)

  # Loop through each item in the array; create the directory and configure permissions
  for directory in "$${directories[@]}"; do
    log "INFO" "Creating $directory"

    mkdir -p $directory
    sudo chown $BOUNDARY_USER:$BOUNDARY_GROUP $directory
    sudo chmod 750 $directory
  done

  log "INFO" "Done creating necessary directories."
}

# install_boundary_binary downloads the Boundary binary and puts it in dedicated bin directory
function install_boundary_binary {
  log "INFO" "Installing Boundary binary to: $BOUNDARY_DIR_BIN..."

  # Download the Boundary binary to the dedicated bin directory
  sudo curl -so $BOUNDARY_DIR_BIN/boundary.zip $BOUNDARY_INSTALL_URL

  # Unzip the Boundary binary
  sudo unzip $BOUNDARY_DIR_BIN/boundary.zip boundary -d $BOUNDARY_DIR_BIN

  sudo rm $BOUNDARY_DIR_BIN/boundary.zip

  log "INFO" "Done installing Boundary binary."
}

function generate_boundary_config {
  declare -l host
  host=$(hostname -s)

  if [[ ${worker_is_internal} == true ]]; then
    addr=$VM_PRIVATE_IP
  else
    addr=$VM_PUBLIC_IP
  fi

  cat >$BOUNDARY_CONFIG_PATH <<EOF
worker {
	public_addr = "$addr" 

%{ if hcp_boundary_cluster_id == "" ~}
  name = "$host"
  initial_upstreams = [
%{ for ip in formatlist("%s",boundary_upstream) ~}
  "${ip}:${boundary_upstream_port}",
%{ endfor ~}
  ]
%{ else ~}
    auth_storage_path = "$BOUNDARY_DIR_DATA"
%{ endif ~}

tags ${worker_tags}
}

%{ if hcp_boundary_cluster_id != "" ~}
hcp_boundary_cluster_id = "${hcp_boundary_cluster_id}"
%{ endif ~}

listener "tcp" {
  address     = "0.0.0.0:9202"
  purpose     = "proxy"
}

listener "tcp" {
  address            = "0.0.0.0:9203"
  purpose            = "ops"
  tls_disable        = true
}

%{ if key_vault_name != "" ~}
kms "azurekeyvault" {
  purpose    = "worker-auth"
  tenant_id  = "${tenant_id}"
  vault_name = "${key_vault_name}"
  key_name   = "worker"
}
%{ endif ~}
EOF
  chown $BOUNDARY_USER:$BOUNDARY_GROUP $BOUNDARY_CONFIG_PATH
  chmod 640 $BOUNDARY_CONFIG_PATH
}

# template_boundary_config templates out the Boundary system file
function template_boundary_systemd {
  log "[INFO]" "Templating out the Boundary service..."

  sudo bash -c "cat > $SYSTEMD_DIR/boundary.service" <<EOF
[Unit]
Description="HashiCorp Boundary"
Documentation=https://www.boundaryproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$BOUNDARY_CONFIG_PATH
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=$BOUNDARY_USER
Group=$BOUNDARY_GROUP
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$BOUNDARY_DIR_BIN/boundary server -config=$BOUNDARY_CONFIG_PATH
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

  # Ensure proper permissions on service file
  sudo chmod 644 $SYSTEMD_DIR/boundary.service

  log "[INFO]" "Done templating out the Boundary service."
}

# start_enable_boundary starts and enables the boundary service
function start_enable_boundary {
  log "[INFO]" "Starting and enabling the boundary service..."

  sudo systemctl enable boundary
  sudo systemctl start boundary

  log "[INFO]" "Done starting and enabling the boundary service."
}

function exit_script {
  if [[ "$1" == 0 ]]; then
    log "INFO" "boundary_custom_data script finished successfully!"
  else
    log "ERROR" "boundary_custom_data script finished with error code $1."
  fi

  exit "$1"
}

function main {
  log "INFO" "Beginning Boundary custom_data script."

  OS_DISTRO=$(detect_os_distro)
  log "INFO" "Detected Linux OS distro is '$OS_DISTRO'."
  install_prereqs "$OS_DISTRO"
  install_azcli "$OS_DISTRO"
  scrape_vm_info
  user_group_create
  directory_create
  install_boundary_binary

  if [[ "${is_govcloud_region}" == "true" ]]; then
    log "INFO" "Setting azure-cli context to AzureUSGovernment environment."
    az cloud set --name AzureUSGovernment
  fi

  log "INFO" "Running 'az login'."
  az login --identity --allow-no-subscriptions

  generate_boundary_config
  template_boundary_systemd
  start_enable_boundary

  log "INFO" "Sleeping for a minute while Boundary initializes."
  sleep 60

  log "INFO" "Polling Boundary health check endpoint until the app becomes ready..."
  while ! curl -ksfS --connect-timeout 5 http://$VM_PRIVATE_IP:9203/health; do
    sleep 5
  done

  exit_script 0
}

main
