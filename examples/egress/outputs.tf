# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------
output "proxy_lb_ip_address" {
  value       = module.boundary_worker.proxy_lb_ip_address
  description = "Private IP address of the Boundary proxy Load Balancer."
}