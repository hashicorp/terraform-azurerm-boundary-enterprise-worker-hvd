# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------
output "proxy_lb_ip_address" {
  description = "Private IP address of the Boundary proxy Load Balancer."
  value       = try(azurerm_lb.boundary_proxy[0].frontend_ip_configuration[0].private_ip_address, null)
}