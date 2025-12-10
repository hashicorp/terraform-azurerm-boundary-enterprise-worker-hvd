# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

data "azurerm_key_vault" "worker" {
  count = var.worker_keyvault_name != "" && var.worker_keyvault_rg_name != "" ? 1 : 0

  name                = var.worker_keyvault_name
  resource_group_name = var.worker_keyvault_rg_name
}
#------------------------------------------------------------------------------
# boundary User-Assigned Identity
#------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "boundary" {

  name                = "${var.friendly_name_prefix}-boundary-worker-msi"
  resource_group_name = local.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "boundary_kv_reader" {
  count = var.worker_keyvault_name != "" && var.worker_keyvault_rg_name != "" ? 1 : 0

  scope                = data.azurerm_key_vault.worker[0].id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.boundary.principal_id
}

resource "azurerm_key_vault_access_policy" "worker_key_vault_worker" {
  count = var.worker_keyvault_name != "" && var.worker_keyvault_rg_name != "" ? 1 : 0

  key_vault_id = data.azurerm_key_vault.worker[0].id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.boundary.principal_id

  key_permissions = [
    "Get", "List", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign",
  ]
}

#------------------------------------------------------------------------------
# VMSS Disk Encryption Set
#------------------------------------------------------------------------------
data "azurerm_disk_encryption_set" "vmss" {
  count = var.vm_disk_encryption_set_name != null && var.vm_disk_encryption_set_rg != null ? 1 : 0

  name                = var.vm_disk_encryption_set_name
  resource_group_name = var.vm_disk_encryption_set_rg
}

resource "azurerm_role_assignment" "boundary_vmss_disk_encryption_set_reader" {
  count = var.vm_disk_encryption_set_name != null && var.vm_disk_encryption_set_rg != null ? 1 : 0

  scope                = data.azurerm_disk_encryption_set.vmss[0].id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.boundary.principal_id
}

