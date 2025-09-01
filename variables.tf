# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "Name of Resource Group to create."
  default     = "boundary-worker-rg"
}

variable "create_resource_group" {
  type        = bool
  description = "Boolean to create a new Resource Group for this boundary deployment."
  default     = true
}

variable "location" {
  type        = string
  description = "Azure region for this boundary deployment."

  validation {
    condition     = contains(["eastus", "westus", "centralus", "eastus2", "westus2", "westeurope", "northeurope", "southeastasia", "eastasia", "australiaeast", "australiasoutheast", "uksouth", "ukwest", "canadacentral", "canadaeast", "southindia", "centralindia", "westindia", "japaneast", "japanwest", "koreacentral", "koreasouth", "francecentral", "southafricanorth", "uaenorth", "brazilsouth", "switzerlandnorth", "germanywestcentral", "norwayeast", "westcentralus"], var.location)
    error_message = "The location specified is not a valid Azure region."
  }
}

variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix for uniquely naming Azure resources. This should be unique across all deployments"

  validation {
    condition     = can(regex("^[[:alnum:]]+$", var.friendly_name_prefix)) && length(var.friendly_name_prefix) < 13
    error_message = "Value can only contain alphanumeric characters and must be less than 13 characters."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable Azure resources."
  default     = {}
}

variable "availability_zones" {
  type        = set(string)
  description = "List of Azure Availability Zones to spread boundary resources across."
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for az in var.availability_zones : contains(["1", "2", "3"], az)])
    error_message = "Availability zone must be one of, or a combination of '1', '2', '3'."
  }
}

variable "is_govcloud_region" {
  type        = bool
  description = "Boolean indicating whether this boundary deployment is in an Azure Government Cloud region."
  default     = false
}

#------------------------------------------------------------------------------
# boundary configuration settings
#------------------------------------------------------------------------------
variable "boundary_version" {
  type        = string
  description = "Version of Boundary to install."
  default     = "0.17.1+ent"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\+ent$", var.boundary_version))
    error_message = "Value must be in the format 'X.Y.Z+ent'."
  }
}

variable "boundary_upstream" {
  type        = list(string)
  description = "List of IP addresses or FQDNs for the worker to initially connect to. This could be a controller or worker. This is not used when connecting to HCP Boundary."
  default     = null
}

variable "boundary_upstream_port" {
  type        = number
  description = "Port for the worker to connect to. Typically 9021 to connect to a controller, 9202 to a worker."
  default     = 9202
}

variable "hcp_boundary_cluster_id" {
  type        = string
  description = "ID of the Boundary cluster in HCP. Only used when using HCP Boundary."
  default     = ""
  validation {
    condition     = var.hcp_boundary_cluster_id == "" ? var.boundary_upstream != null : true
    error_message = "If `hcp_boundary_cluster_id` is set, `boundary_upstream` must be null."
  }
}

variable "worker_keyvault_name" {
  type        = string
  description = "Name of the Key Vault that contains the worker key to use."
  default     = ""
}

variable "worker_keyvault_rg_name" {
  type        = string
  description = "Name of the Resource Group where the 'worker' Key Vault resides."
  default     = ""
}

variable "worker_tags" {
  type        = map(string)
  description = "Map of extra tags to apply to Boundary Worker Configuration. var.common_tags will be merged with this map."
  default     = {}
}

variable "additional_package_names" {
  type        = set(string)
  description = "List of additional repository package names to install"
  default     = []
}
#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
variable "worker_subnet_id" {
  type        = string
  description = "Subnet ID for worker VMs."
}

variable "lb_subnet_id" {
  type        = string
  description = "Subnet ID for worker proxy load balancer."
  default     = null
}

variable "worker_is_internal" {
  type        = bool
  description = "Boolean to create give the worker an internal IP address only or give it an external IP address."
  default     = true
}

variable "create_lb" {
  type        = bool
  description = "Boolean to create a Network Load Balancer for Boundary. Should be true if downstream workers will connect to these workers."
  default     = false
  validation {
    condition     = var.create_lb == true ? var.lb_subnet_id != null : true
    error_message = "The `lb_subnet_id` must be provided if `create_lb` is set to `true`."
  }
}

variable "lb_private_ip" {
  type        = string
  description = "Private IP address for internal Azure Load Balancer."
  default     = null
  validation {
    condition     = var.lb_private_ip != null ? var.create_lb != null : true
    error_message = "`lb_private_ip` must be provided if `create_lb` is set to `true`."
  }
}

#------------------------------------------------------------------------------
# Virtual Machine Scaleset (VMSS)
#------------------------------------------------------------------------------
variable "vmss_vm_count" {
  type        = number
  description = "Number of VM instances in the VMSS."
  default     = 1
}

variable "vm_sku" {
  type        = string
  description = "SKU for VM size for the VMSS. Regions may have different skus available"
  default     = "Standard_D2s_v5"

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+$", var.vm_sku))
    error_message = "Value can only contain alphanumeric characters and underscores."
  }
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for VMs in VMSS."
  default     = "boundaryadmin"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "SSH public key for VMs in VMSS."
  default     = null
}

variable "vm_custom_image_name" {
  type        = string
  description = "Name of custom VM image to use for VMSS. If not using a custom image, leave this blank."
  default     = null
}

variable "vm_custom_image_rg_name" {
  type        = string
  description = "Resource Group name where the custom VM image resides. Only valid if `vm_custom_image_name` is not null."
  default     = null
}
variable "vm_os_image" {
  description = "The OS image to use for the VM. Options are: redhat8, redhat9, ubuntu2204, ubuntu2404."
  type        = string
  default     = "ubuntu2404"

  validation {
    condition     = contains(["redhat8", "redhat9", "ubuntu2204", "ubuntu2404"], var.vm_os_image)
    error_message = "Value must be one of 'redhat8', 'redhat9', 'ubuntu2204', or 'ubuntu2404'."
  }
}
variable "vm_disk_encryption_set_name" {
  type        = string
  description = "Name of the Disk Encryption Set to use for VMSS."
  default     = null
}

variable "vm_disk_encryption_set_rg" {
  type        = string
  description = "Name of the Resource Group where the Disk Encryption Set to use for VMSS exists."
  default     = null
}

variable "vm_enable_boot_diagnostics" {
  type        = bool
  description = "Boolean to enable boot diagnostics for VMSS."
  default     = false
}

variable "vmss_availability_zones" {
  type        = set(string)
  description = "List of Azure Availability Zones to spread the VMSS VM resources across."
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for az in var.vmss_availability_zones : contains(["1", "2", "3"], az)])
    error_message = "Availability zone must be one of, or a combination of '1', '2', '3'."
  }
}
variable "custom_startup_script_template" {
  type        = string
  description = "Name of custom startup script template file. File must exist within a directory named `./templates` within your current working directory."
  default     = null

  validation {
    condition     = var.custom_startup_script_template != null ? fileexists("${path.cwd}/templates/${var.custom_startup_script_template}") : true
    error_message = "File not found. Ensure the file exists within a directory named `./templates` within your current working directory."
  }
}
