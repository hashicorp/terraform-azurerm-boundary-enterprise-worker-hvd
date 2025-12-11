# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.101"
    }
  }
}

provider "azurerm" {
  features {}
}

module "boundary_worker" {
  source = "../.."

  # Common
  friendly_name_prefix = var.friendly_name_prefix
  location             = var.location
  common_tags          = var.common_tags
  resource_group_name  = var.resource_group_name

  # Boundary configuration settings
  hcp_boundary_cluster_id = var.hcp_boundary_cluster_id
  worker_is_internal      = var.worker_is_internal
  worker_tags             = var.worker_tags

  # Networking
  worker_subnet_id = var.worker_subnet_id
  create_lb        = var.create_lb
  lb_subnet_id     = var.lb_subnet_id
  lb_private_ip    = var.lb_private_ip

  # Compute
  vmss_vm_count              = var.vmss_vm_count
  vm_ssh_public_key          = var.vm_ssh_public_key
  vm_enable_boot_diagnostics = var.vm_enable_boot_diagnostics
  vm_sku                     = var.vm_sku
  vmss_availability_zones    = var.vmss_availability_zones
}
