# Boundary Enterprise Worker HVD on Azure VM

Terraform module aligned with HashiCorp Validated Designs (HVD) to deploy Boundary Enterprise Worker(s) on Microsoft Azure using Azure Virtual Machines. This module is designed to work with the complimentary [Boundary Enterprise Controller HVD on Azure VM](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-controller-hvd) module.

## Prerequisites

### General

- Terraform CLI `>= 1.9` installed on workstation
- Azure subscription that Boundary Controller will be hosted in with admin-like permissions to provision resources in via Terraform CLI
- Azure Blob Storage Account for [AzureRM Remote State backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html) is recommended but not required
- `Git` CLI and Visual Studio Code editor installed on workstation are recommended but not required

### Networking

- Azure VNet ID
- Worker subnet ID with service endpoints enabled for `Microsoft.KeyVault`
- Worker subnet requires access to the subnet(s) that contain either the controller(s) or upstream worker(s)
- Load balancer subnet ID for proxy lb if it will be deployed.
- Load balancer static IP address for proxy LB if it will be deployed.
- Network Security Group (NSG)/firewall rules:
  - Allow `TCP/9202` ingress from subnets that will contain Boundary worker(s) that will connect to workers deployed by this module
  - Allow `TCP/9202` ingress from subnets that will contain Boundary clients that will use these workers deployed by this module.

### Key Vault

- Azure Key Vault containing the worker-auth key deployed by the Boundary controller module, unless connecting to HCP Boundary
  - >📝 Note: This module will create a MSI and Key Vault Access policy on the Key Vault specified.
- A mechanism for shell access to Azure Linux VMs within VMSS (SSH key pair, bastion host, username/password, etc.)

### Compute

One of the following mechanisms for shell access to Boundary instances:

- A mechanism for shell access to Azure Linux VMs within VMSS (SSH key pair, bastion host, username/password, etc.)

### Boundary

Unless deploying a Boundary HCP Worker, you will require a Boundary Enterprise Cluster deployed using the [Boundary Enterprise Controller HVD on Azure VM](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-controller-hvd) module.

## Usage - Boundary Enterprise

1. Create/configure/validate the applicable [prerequisites](#prerequisites).

1. Referencing the [examples](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/0.2.0/examples/) directory, copy the Terraform files from your scenario of choice into an appropriate destination to create your own root Terraform configuration. Populate your own custom values in the __example terraform.tfvars__ provided within the subdirectory of your scenario of choice (example [here](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/0.2.0/examples/main/terraform.tfvars.example)) file and remove the `.example` file extension.

    >📝 Note: The `friendly_name_prefix` variable should be unique for every agent deployment.

1. Update the __backend.tf__ file within your newly created Terraform root configuration with your [AzureRM remote state backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html) configuration values.

1. Run `terraform init` and `terraform apply` against your newly created Terraform root configuration.

1. After the `terraform apply` finishes successfully, you can monitor the install progress by connecting to the VM in your Boundary worker Virtual Machine Scaleset (VMSS) via SSH and observing the cloud-init logs:

   ```sh
   tail -f /var/log/boundary-cloud-init.log

   journalctl -xu cloud-final -f
   ```

1. Once the cloud-init script finishes successfully, while still connected to the VM via SSH you can check the status of the boundary service:

   ```sh
   sudo systemctl status boundary
   ```

1. Worker should show up in Boundary console

## Usage - HCP Boundary

1. In HCP Boundary go to `Workers` and start creating a new worker. Copy the `Boundary Cluster ID`.

1. Create/configure/validate the applicable [prerequisites](#prerequisites).

1. Referencing the [examples](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/0.2.0/examples/) directory, copy the Terraform files from your scenario of choice into an appropriate destination to create your own root Terraform configuration. Populate your own custom values in the __example terraform.tfvars__ provided within the subdirectory of your scenario of choice (example [here](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/0.2.0/examples/main/terraform.tfvars.example)) file and remove the `.example` file extension. Set the `hcp_boundary_cluster_id` variable with the Boundary Cluster ID from step 1.

    >📝 Note: The `friendly_name_prefix` variable should be unique for every agent deployment.

1. Update the __backend.tf__ file within your newly created Terraform root configuration with your [AzureRM remote state backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html) configuration values.

1. Run `terraform init` and `terraform apply` against your newly created Terraform root configuration.

1. After the `terraform apply` finishes successfully, you can monitor the install progress by connecting to the VM in your Boundary worker Virtual Machine Scaleset (VMSS) via SSH and observing the cloud-init logs:

   ```sh
   tail -f /var/log/boundary-cloud-init.log

   journalctl -xu cloud-final -f
   ```

1. Once the cloud-init script finishes successfully, while still connected to the VM via SSH you can check the status of the boundary service:

   ```sh
   sudo systemctl status boundary
   ```

1. While still connected via SSH to the Boundary Worker, `sudo journalctl -xu boundary` to review the Boundary Logs.

1. Copy the `Worker Auth Registration Request` string and paste this into the `Worker Auth Registration Request` field of the new Boundary Worker in the HCP console and click `Register Worker`.

1. Worker should show up in HCP Boundary console

## Docs

Below are links to docs pages related to deployment customizations and day 2 operations of your Boundary Controller instance.

- [Deployment Customizations](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/main/docs/deployment-customizations.md)
- [Upgrading Boundary version](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/main/docs/boundary-version-upgrades.md)
- [Updating/modifying Boundary configuration settings](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/main/docs/boundary-config-settings.md)
- [Deploying in Azure GovCloud](https://github.com/hashicorp/terraform-azurerm-boundary-enterprise-worker-hvd/blob/0.2.0/docs/govcloud-deployment.md)

## Module support

This open source software is maintained by the HashiCorp Technical Field Organization, independently of our enterprise products. While our Support Engineering team provides dedicated support for our enterprise offerings, this open source software is not included.

- For help using this open source software, please engage your account team.
- To report bugs/issues with this open source software, please open them directly against this code repository using the GitHub issues feature.

Please note that there is no official Service Level Agreement (SLA) for support of this software as a HashiCorp customer. This software falls under the definition of Community Software/Versions in your Agreement. We appreciate your understanding and collaboration in improving our open source projects.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.101 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.101 |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_access_policy.worker_key_vault_worker](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_lb.boundary_proxy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.boundary_proxy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.boundary_proxy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.boundary_proxy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_linux_virtual_machine_scale_set.boundary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) | resource |
| [azurerm_resource_group.boundary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.boundary_kv_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.boundary_vmss_disk_encryption_set_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.boundary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_disk_encryption_set.vmss](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/disk_encryption_set) | data source |
| [azurerm_image.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/image) | data source |
| [azurerm_key_vault.worker](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_platform_image.latest_os_image](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/platform_image) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix for uniquely naming Azure resources. This should be unique across all deployments | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for this boundary deployment. | `string` | n/a | yes |
| <a name="input_worker_subnet_id"></a> [worker\_subnet\_id](#input\_worker\_subnet\_id) | Subnet ID for worker VMs. | `string` | n/a | yes |
| <a name="input_additional_package_names"></a> [additional\_package\_names](#input\_additional\_package\_names) | List of additional repository package names to install | `set(string)` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Azure Availability Zones to spread boundary resources across. | `set(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_boundary_upstream"></a> [boundary\_upstream](#input\_boundary\_upstream) | List of IP addresses or FQDNs for the worker to initially connect to. This could be a controller or worker. This is not used when connecting to HCP Boundary. | `list(string)` | `null` | no |
| <a name="input_boundary_upstream_port"></a> [boundary\_upstream\_port](#input\_boundary\_upstream\_port) | Port for the worker to connect to. Typically 9021 to connect to a controller, 9202 to a worker. | `number` | `9202` | no |
| <a name="input_boundary_version"></a> [boundary\_version](#input\_boundary\_version) | Version of Boundary to install. | `string` | `"0.17.1+ent"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for taggable Azure resources. | `map(string)` | `{}` | no |
| <a name="input_create_lb"></a> [create\_lb](#input\_create\_lb) | Boolean to create a Network Load Balancer for Boundary. Should be true if downstream workers will connect to these workers. | `bool` | `false` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Boolean to create a new Resource Group for this boundary deployment. | `bool` | `true` | no |
| <a name="input_custom_startup_script_template"></a> [custom\_startup\_script\_template](#input\_custom\_startup\_script\_template) | Name of custom startup script template file. File must exist within a directory named `./templates` within your current working directory. | `string` | `null` | no |
| <a name="input_hcp_boundary_cluster_id"></a> [hcp\_boundary\_cluster\_id](#input\_hcp\_boundary\_cluster\_id) | ID of the Boundary cluster in HCP. Only used when using HCP Boundary. | `string` | `""` | no |
| <a name="input_is_govcloud_region"></a> [is\_govcloud\_region](#input\_is\_govcloud\_region) | Boolean indicating whether this boundary deployment is in an Azure Government Cloud region. | `bool` | `false` | no |
| <a name="input_lb_private_ip"></a> [lb\_private\_ip](#input\_lb\_private\_ip) | Private IP address for internal Azure Load Balancer. | `string` | `null` | no |
| <a name="input_lb_subnet_id"></a> [lb\_subnet\_id](#input\_lb\_subnet\_id) | Subnet ID for worker proxy load balancer. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of Resource Group to create. | `string` | `"boundary-worker-rg"` | no |
| <a name="input_vm_admin_username"></a> [vm\_admin\_username](#input\_vm\_admin\_username) | Admin username for VMs in VMSS. | `string` | `"boundaryadmin"` | no |
| <a name="input_vm_custom_image_name"></a> [vm\_custom\_image\_name](#input\_vm\_custom\_image\_name) | Name of custom VM image to use for VMSS. If not using a custom image, leave this blank. | `string` | `null` | no |
| <a name="input_vm_custom_image_rg_name"></a> [vm\_custom\_image\_rg\_name](#input\_vm\_custom\_image\_rg\_name) | Resource Group name where the custom VM image resides. Only valid if `vm_custom_image_name` is not null. | `string` | `null` | no |
| <a name="input_vm_disk_encryption_set_name"></a> [vm\_disk\_encryption\_set\_name](#input\_vm\_disk\_encryption\_set\_name) | Name of the Disk Encryption Set to use for VMSS. | `string` | `null` | no |
| <a name="input_vm_disk_encryption_set_rg"></a> [vm\_disk\_encryption\_set\_rg](#input\_vm\_disk\_encryption\_set\_rg) | Name of the Resource Group where the Disk Encryption Set to use for VMSS exists. | `string` | `null` | no |
| <a name="input_vm_enable_boot_diagnostics"></a> [vm\_enable\_boot\_diagnostics](#input\_vm\_enable\_boot\_diagnostics) | Boolean to enable boot diagnostics for VMSS. | `bool` | `false` | no |
| <a name="input_vm_os_image"></a> [vm\_os\_image](#input\_vm\_os\_image) | The OS image to use for the VM. Options are: redhat8, redhat9, ubuntu2204, ubuntu2404. | `string` | `"ubuntu2404"` | no |
| <a name="input_vm_sku"></a> [vm\_sku](#input\_vm\_sku) | SKU for VM size for the VMSS. Regions may have different skus available | `string` | `"Standard_D2s_v5"` | no |
| <a name="input_vm_ssh_public_key"></a> [vm\_ssh\_public\_key](#input\_vm\_ssh\_public\_key) | SSH public key for VMs in VMSS. | `string` | `null` | no |
| <a name="input_vmss_availability_zones"></a> [vmss\_availability\_zones](#input\_vmss\_availability\_zones) | List of Azure Availability Zones to spread the VMSS VM resources across. | `set(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_vmss_vm_count"></a> [vmss\_vm\_count](#input\_vmss\_vm\_count) | Number of VM instances in the VMSS. | `number` | `1` | no |
| <a name="input_worker_is_internal"></a> [worker\_is\_internal](#input\_worker\_is\_internal) | Boolean to create give the worker an internal IP address only or give it an external IP address. | `bool` | `true` | no |
| <a name="input_worker_keyvault_name"></a> [worker\_keyvault\_name](#input\_worker\_keyvault\_name) | Name of the Key Vault that contains the worker key to use. | `string` | `""` | no |
| <a name="input_worker_keyvault_rg_name"></a> [worker\_keyvault\_rg\_name](#input\_worker\_keyvault\_rg\_name) | Name of the Resource Group where the 'worker' Key Vault resides. | `string` | `""` | no |
| <a name="input_worker_tags"></a> [worker\_tags](#input\_worker\_tags) | Map of extra tags to apply to Boundary Worker Configuration. var.common\_tags will be merged with this map. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_proxy_lb_ip_address"></a> [proxy\_lb\_ip\_address](#output\_proxy\_lb\_ip\_address) | Private IP address of the Boundary proxy Load Balancer. |
<!-- END_TF_DOCS -->
