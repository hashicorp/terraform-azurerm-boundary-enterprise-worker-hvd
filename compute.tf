# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Custom Data (cloud-init) arguments
#------------------------------------------------------------------------------
locals {
  custom_startup_script_template = var.custom_startup_script_template != null ? "${path.cwd}/templates/${var.custom_startup_script_template}" : "${path.module}/templates/boundary_custom_data.sh.tpl"

  custom_data_args = {
    # used to set azure-cli context to AzureUSGovernment
    is_govcloud_region = var.is_govcloud_region

    # https://developer.hashicorp.com/boundary/docs/configuration/worker

    # Boundary settings
    boundary_version         = var.boundary_version
    boundary_upstream        = var.boundary_upstream
    boundary_upstream_port   = var.boundary_upstream_port
    worker_is_internal       = var.worker_is_internal
    hcp_boundary_cluster_id  = var.hcp_boundary_cluster_id
    boundary_version         = var.boundary_version
    systemd_dir              = "/etc/systemd/system"
    boundary_dir_bin         = "/usr/bin"
    boundary_dir_config      = "/etc/boundary.d"
    boundary_dir_home        = "/opt/boundary"
    boundary_install_url     = format("https://releases.hashicorp.com/boundary/%s/boundary_%s_linux_amd64.zip", var.boundary_version, var.boundary_version)
    worker_tags              = lower(replace(jsonencode(merge(var.common_tags, var.worker_tags)), ":", "="))
    tenant_id                = data.azurerm_client_config.current.tenant_id
    additional_package_names = join(" ", var.additional_package_names)

    # key_vault settings
    key_vault_name = var.worker_keyvault_name != "" && var.worker_keyvault_rg_name != "" ? data.azurerm_key_vault.worker[0].name : ""
  }
}


#------------------------------------------------------------------------------
# Virtual Machine Scale Set (VMSS)
#------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "boundary" {
  name                = "${var.friendly_name_prefix}-boundary-worker-vmss"
  resource_group_name = local.resource_group_name
  location            = var.location
  instances           = var.vmss_vm_count
  sku                 = var.vm_sku
  admin_username      = var.vm_admin_username
  overprovision       = false
  upgrade_mode        = "Manual"
  zone_balance        = true
  zones               = var.vmss_availability_zones
  health_probe_id     = var.create_lb == false ? null : azurerm_lb_probe.boundary_proxy[0].id
  custom_data         = base64encode(templatefile("${local.custom_startup_script_template}", local.custom_data_args))
  scale_in {
    rule = "OldestVM"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.boundary.id]
  }

  dynamic "admin_ssh_key" {
    for_each = var.vm_ssh_public_key != null ? [1] : []

    content {
      username   = var.vm_admin_username
      public_key = var.vm_ssh_public_key
    }
  }

  source_image_id = var.vm_custom_image_name == null ? null : data.azurerm_image.custom[0].id

  dynamic "source_image_reference" {
    for_each = var.vm_custom_image_name == null ? [true] : []

    content {
      publisher = local.vm_image_publisher
      offer     = local.vm_image_offer
      sku       = local.vm_image_sku
      version   = data.azurerm_platform_image.latest_os_image.version
    }
  }

  network_interface {
    name    = "boundary-vm-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.worker_subnet_id
      load_balancer_backend_address_pool_ids = var.create_lb == false ? null : [azurerm_lb_backend_address_pool.boundary_proxy[0].id]

      dynamic "public_ip_address" {
        for_each = var.worker_is_internal == true ? [] : [1]

        content {
          name = "public"
        }
      }
    }
  }

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_size_gb           = 64
    disk_encryption_set_id = var.vm_disk_encryption_set_name != null && var.vm_disk_encryption_set_rg != null ? data.azurerm_disk_encryption_set.vmss[0].id : null
  }

  dynamic "boot_diagnostics" {
    for_each = var.vm_enable_boot_diagnostics == true ? [1] : []
    content {}
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-boundary-worker-vmss" },
    var.common_tags
  )
}

# ------------------------------------------------------------------------------
# Debug rendered boundary custom_data script from template
# ------------------------------------------------------------------------------
# Uncomment this block to debug the rendered boundary custom_data script
# resource "local_file" "debug_custom_data" {
#   content  = templatefile("${path.module}/templates/boundary_custom_data.sh.tpl", local.custom_data_args)
#   filename = "${path.module}/debug/debug_boundary_custom_data.sh"
# }
