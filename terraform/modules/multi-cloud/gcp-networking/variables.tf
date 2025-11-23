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

variable "labels_override" {
  description = "Labels that override default labels"
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "Whether to create subnetworks automatically"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Network routing mode (GLOBAL or REGIONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "delete_default_routes_on_create" {
  description = "Whether to delete default routes on creation"
  type        = bool
  default     = false
}

variable "mtu" {
  description = "Maximum transmission unit"
  type        = number
  default     = 1460
}

variable "subnets" {
  description = "Subnet configurations"
  type = map(object({
    name                     = string
    ip_cidr_range            = string
    region                   = string
    description              = optional(string)
    private_ip_google_access = optional(bool, false)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    enable_flow_logs               = optional(bool, false)
    flow_log_aggregation_interval  = optional(string, "INTERVAL_5_SEC")
    flow_log_sampling              = optional(number, 0.5)
    flow_log_metadata              = optional(string, "INCLUDE_ALL_METADATA")
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Firewall rule configurations"
  type = map(object({
    name          = string
    description   = optional(string)
    direction     = optional(string, "INGRESS")
    priority      = optional(number, 1000)
    source_ranges = optional(list(string), [])
    destination_ranges = optional(list(string), [])
    source_tags = optional(list(string), [])
    target_tags = optional(list(string), [])
    source_service_accounts = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
    denied = optional(list(object({
      ip_protocol = string
      ports       = optional(list(string))
    })), [])
    allowed = optional(list(object({
      ip_protocol = string
      ports       = optional(list(string))
    })), [])
    enable_logging = optional(bool, false)
    log_metadata   = optional(string, "INCLUDE_ALL_METADATA")
  }))
  default = {}
}

variable "routers" {
  description = "Router configurations"
  type = map(object({
    name    = string
    region  = string
    bgp_asn = number
    advertise_mode    = optional(string, "DEFAULT")
    advertised_groups = optional(list(string), [])
    advertised_ip_ranges = optional(map(string), {})
    nats = optional(map(object({
      nat_ip_allocate_option = optional(string, "AUTO_ONLY")
      source_subnetwork_ip_ranges_to_nat = optional(object({
        all = optional(bool, false)
        subnetworks = optional(list(string), [])
      }), null)
      nat_ips = optional(list(string), [])
      enable_nat_logging = optional(bool, false)
      nat_log_filter     = optional(string, "ALL")
    })), {})
  }))
  default = {}
}

variable "routes" {
  description = "Route configurations"
  type = map(object({
    name                   = string
    dest_range            = string
    next_hop_ip           = optional(string)
    next_hop_instance     = optional(string)
    next_hop_instance_zone = optional(string)
    next_hop_vpn_tunnel   = optional(string)
    priority              = optional(number, 1000)
    tags                  = optional(list(string), [])
  }))
  default = {}
}

variable "external_addresses" {
  description = "External IP address configurations"
  type = map(object({
    name         = string
    address_type = optional(string, "EXTERNAL")
    region       = optional(string)
    description  = optional(string)
  }))
  default = {}
}

variable "global_addresses" {
  description = "Global IP address configurations"
  type = map(object({
    name         = string
    address_type = optional(string, "EXTERNAL")
    description  = optional(string)
  }))
  default = {}
}

variable "vpn_gateways" {
  description = "VPN gateway configurations"
  type = map(object({
    name   = string
    region = string
  }))
  default = {}
}

variable "ha_vpn_gateways" {
  description = "HA VPN gateway configurations"
  type = map(object({
    name   = string
    region = string
  }))
  default = {}
}

variable "network_peerings" {
  description = "Network peering configurations"
  type = map(object({
    peer_network           = string
    export_custom_routes   = optional(bool, false)
    import_custom_routes   = optional(bool, false)
    stack_type            = optional(string)
  }))
  default = {}
}

variable "interconnect_attachments" {
  description = "Interconnect attachment configurations"
  type = map(object({
    name         = string
    interconnect = string
    router       = string
    region       = string
    bandwidth    = string
    type         = string
    candidate_subnets = optional(list(string), [])
    admin_enabled = optional(bool, true)
    mtu           = optional(number, 1500)
  }))
  default = {}
}

variable "service_networking" {
  description = "Service networking configurations"
  type = map(object({
    service                = string
    reserved_peering_ranges = list(string)
  }))
  default = {}
}
