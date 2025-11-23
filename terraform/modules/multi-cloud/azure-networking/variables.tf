variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "service" {
  description = "Service name"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags that override default tags"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "DNS servers for the virtual network"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Subnet configurations"
  type = map(object({
    name          = string
    address_prefix = string
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }), null)
    private_endpoint_network_policies = optional(object({
      enabled = bool
    }), null)
    private_link_service_network_policies = optional(object({
      enabled = bool
    }), null)
  }))
  default = {}
}

variable "network_security_groups" {
  description = "Network security group configurations"
  type = map(object({
    name = string
    security_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  description = "Associations between subnets and network security groups"
  type = map(object({
    subnet_name = string
    nsg_name    = string
  }))
  default = {}
}

variable "route_tables" {
  description = "Route table configurations"
  type = map(object({
    name = string
    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), [])
  }))
  default = {}
}

variable "subnet_route_associations" {
  description = "Associations between subnets and route tables"
  type = map(object({
    subnet_name      = string
    route_table_name = string
  }))
  default = {}
}

variable "public_ips" {
  description = "Public IP configurations"
  type = map(object({
    name              = string
    allocation_method = optional(string, "Static")
    sku               = optional(string, "Standard")
    zones             = optional(list(string))
    domain_name_label = optional(string)
  }))
  default = {}
}

variable "network_interfaces" {
  description = "Network interface configurations"
  type = map(object({
    name                  = string
    subnet_name           = string
    ip_config_name        = optional(string, "internal")
    private_ip_allocation = optional(string, "Dynamic")
    public_ip_name        = optional(string)
  }))
  default = {}
}

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_name" {
  description = "Name of the VPN gateway"
  type        = string
  default     = "vpn-gateway"
}

variable "vpn_gateway_type" {
  description = "Type of VPN gateway"
  type        = string
  default     = "Vpn"
}

variable "vpn_type" {
  description = "VPN type"
  type        = string
  default     = "RouteBased"
}

variable "vpn_gateway_config" {
  description = "VPN gateway configuration"
  type = object({
    active_active = optional(bool, false)
    enable_bgp    = optional(bool, false)
  })
  default = {}
}

variable "vpn_gateway_sku" {
  description = "VPN gateway SKU"
  type        = string
  default     = "VpnGw1"
}

variable "vpn_gateway_public_ip" {
  description = "Name of the public IP for VPN gateway"
  type        = string
  default     = "vpn-gateway-pip"
}

variable "vnet_peerings" {
  description = "Virtual network peerings"
  type = map(object({
    remote_vnet_id               = string
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  }))
  default = {}
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = ""
}

variable "enable_network_watcher" {
  description = "Enable Network Watcher"
  type        = bool
  default     = false
}

variable "network_watcher_name" {
  description = "Name of the Network Watcher"
  type        = string
  default     = "network-watcher"
}

variable "enable_flow_logs" {
  description = "Enable flow logs"
  type        = bool
  default     = false
}

variable "flow_log_storage_account_id" {
  description = "Storage account ID for flow logs"
  type        = string
  default     = ""
}

variable "flow_log_retention_days" {
  description = "Retention period for flow logs in days"
  type        = number
  default     = 7
}
