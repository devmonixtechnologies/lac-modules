terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

module "tags" {
  source          = "../../shared/tags"
  environment     = var.environment
  service         = var.service
  component       = "azure-networking"
  additional_tags = var.tags
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(module.tags.tags, var.tags_override)
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_servers         = var.dns_servers

  tags = merge(module.tags.tags, var.tags_override)

  dynamic "subnet" {
    for_each = var.subnets
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.address_prefix]

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }

  dynamic "private_endpoint_network_policies" {
    for_each = lookup(each.value, "private_endpoint_network_policies", null) != null ? [each.value.private_endpoint_network_policies] : []
    content {
      enabled = private_endpoint_network_policies.value.enabled
    }
  }

  dynamic "private_link_service_network_policies" {
    for_each = lookup(each.value, "private_link_service_network_policies", null) != null ? [each.value.private_link_service_network_policies] : []
    content {
      enabled = private_link_service_network_policies.value.enabled
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(module.tags.tags, var.tags_override)

  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rules", [])
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = lookup(security_rule.value, "destination_port_range", "*")
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", "*")
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", "*")
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_nsg_associations

  subnet_id                 = azurerm_subnet.this[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_name].id
}

resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(module.tags.tags, var.tags_override)

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.subnet_route_associations

  subnet_id      = azurerm_subnet.this[each.value.subnet_name].id
  route_table_id = azurerm_route_table.this[each.value.route_table_name].id
}

resource "azurerm_public_ip" "this" {
  for_each = var.public_ips

  name                = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = lookup(each.value, "allocation_method", "Static")
  sku                 = lookup(each.value, "sku", "Standard")
  zones               = lookup(each.value, "zones", null)
  domain_name_label   = lookup(each.value, "domain_name_label", null)

  tags = merge(module.tags.tags, var.tags_override)
}

resource "azurerm_network_interface" "this" {
  for_each = var.network_interfaces

  name                = each.value.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = lookup(each.value, "ip_config_name", "internal")
    subnet_id                     = azurerm_subnet.this[each.value.subnet_name].id
    private_ip_address_allocation = lookup(each.value, "private_ip_allocation", "Dynamic")
    public_ip_address_id          = lookup(each.value, "public_ip_name", null) != null ? azurerm_public_ip.this[each.value.public_ip_name].id : null
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "azurerm_virtual_network_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = var.vpn_gateway_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type     = var.vpn_gateway_type
  vpn_type = var.vpn_type

  active_active = lookup(var.vpn_gateway_config, "active_active", false)
  enable_bgp    = lookup(var.vpn_gateway_config, "enable_bgp", false)

  sku = var.vpn_gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.this[var.vpn_gateway_public_ip].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "azurerm_virtual_network_peering" "this" {
  for_each = var.vnet_peerings

  name                      = each.key
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = each.value.remote_vnet_id
  allow_virtual_network_access = lookup(each.value, "allow_virtual_network_access", true)
  allow_forwarded_traffic      = lookup(each.value, "allow_forwarded_traffic", false)
  allow_gateway_transit        = lookup(each.value, "allow_gateway_transit", false)
  use_remote_gateways          = lookup(each.value, "use_remote_gateways", false)
}

resource "azurerm_monitor_diagnostic_setting" "vnet_logs" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${azurerm_virtual_network.this.name}-diagnostic"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_network_watcher" "this" {
  count = var.enable_network_watcher ? 1 : 0

  name                = var.network_watcher_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(module.tags.tags, var.tags_override)
}

resource "azurerm_network_watcher_flow_log" "this" {
  count = var.enable_network_watcher && var.enable_flow_logs ? 1 : 0

  network_watcher_name = azurerm_network_watcher.this[0].name
  resource_group_name  = azurerm_resource_group.this.name
  name                = "${azurerm_virtual_network.this.name}-flow-log"
  location            = azurerm_resource_group.this.location
  network_security_group_id = azurerm_network_security_group.this[values(var.network_security_groups)[0].name].id
  storage_account_id        = var.flow_log_storage_account_id
  enabled                   = true

  retention_policy {
    days = var.flow_log_retention_days
  }

  traffic_analytics {
    interval_in_minutes   = 10
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_workspace_id
  }
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.this.id
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "network_security_group_ids" {
  description = "IDs of the network security groups"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "public_ip_addresses" {
  description = "Public IP addresses"
  value       = { for k, v in azurerm_public_ip.this : k => v.ip_address }
}

output "vpn_gateway_id" {
  description = "ID of the VPN gateway"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.this[0].id : null
}
