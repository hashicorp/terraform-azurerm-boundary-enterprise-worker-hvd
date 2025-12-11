# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# proxy Load Balancer
#------------------------------------------------------------------------------
resource "azurerm_lb" "boundary_proxy" {
  count = var.create_lb == true ? 1 : 0


  name                = "${var.friendly_name_prefix}-boundary-proxy-lb"
  resource_group_name = local.resource_group_name
  location            = var.location
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                          = "boundary-proxy-frontend-internal"
    zones                         = var.availability_zones
    subnet_id                     = var.lb_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lb_private_ip
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-boundary-proxy-lb" },
    var.common_tags
  )
}

resource "azurerm_lb_backend_address_pool" "boundary_proxy" {
  count = var.create_lb == true ? 1 : 0

  name            = "${var.friendly_name_prefix}-boundary-proxy-backend"
  loadbalancer_id = azurerm_lb.boundary_proxy[0].id
}

resource "azurerm_lb_probe" "boundary_proxy" {
  count = var.create_lb == true ? 1 : 0

  name                = "boundary-proxy-controller-lb-probe"
  loadbalancer_id     = azurerm_lb.boundary_proxy[0].id
  protocol            = "Http"
  port                = 9203
  request_path        = "/health"
  interval_in_seconds = 15
  number_of_probes    = 5
}

resource "azurerm_lb_rule" "boundary_proxy" {
  count = var.create_lb == true ? 1 : 0

  name                           = "${var.friendly_name_prefix}-boundary-proxy-lb-rule-app"
  loadbalancer_id                = azurerm_lb.boundary_proxy[0].id
  probe_id                       = azurerm_lb_probe.boundary_proxy[0].id
  protocol                       = "Tcp"
  frontend_ip_configuration_name = azurerm_lb.boundary_proxy[0].frontend_ip_configuration[0].name
  frontend_port                  = 9202
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.boundary_proxy[0].id]
  backend_port                   = 9202
}