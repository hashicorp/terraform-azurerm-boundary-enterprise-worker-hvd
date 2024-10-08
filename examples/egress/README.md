<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.101 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_boundary_worker"></a> [boundary\_worker](#module\_boundary\_worker) | ../.. | n/a |

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
| <a name="input_vm_image_offer"></a> [vm\_image\_offer](#input\_vm\_image\_offer) | Offer of the VM image. | `string` | `"0001-com-ubuntu-server-jammy"` | no |
| <a name="input_vm_image_publisher"></a> [vm\_image\_publisher](#input\_vm\_image\_publisher) | Publisher of the VM image. | `string` | `"Canonical"` | no |
| <a name="input_vm_image_sku"></a> [vm\_image\_sku](#input\_vm\_image\_sku) | SKU of the VM image. | `string` | `"22_04-lts-gen2"` | no |
| <a name="input_vm_image_version"></a> [vm\_image\_version](#input\_vm\_image\_version) | Version of the VM image. | `string` | `"latest"` | no |
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