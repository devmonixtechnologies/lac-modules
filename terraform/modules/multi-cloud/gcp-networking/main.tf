terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

module "tags" {
  source          = "../../shared/tags"
  environment     = var.environment
  service         = var.service
  component       = "gcp-networking"
  additional_tags = var.tags
}

data "google_project" "project" {}

resource "google_compute_network" "this" {
  name                            = var.network_name
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
  mtu                             = var.mtu

  project = var.project_id

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name                     = each.value.name
  ip_cidr_range            = each.value.ip_cidr_range
  region                   = each.value.region
  network                  = google_compute_network.this.name
  private_ip_google_access = lookup(each.value, "private_ip_google_access", false)
  description              = lookup(each.value, "description", "")

  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ip_ranges", [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = lookup(each.value, "enable_flow_logs", false) ? [1] : []
    content {
      aggregation_interval = lookup(each.value, "flow_log_aggregation_interval", "INTERVAL_5_SEC")
      flow_sampling         = lookup(each.value, "flow_log_sampling", 0.5)
      metadata              = lookup(each.value, "flow_log_metadata", "INCLUDE_ALL_METADATA")
    }
  }

  project = var.project_id

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_compute_firewall" "this" {
  for_each = var.firewall_rules

  name    = each.value.name
  network = google_compute_network.this.name
  project = var.project_id

  description          = lookup(each.value, "description", "")
  direction            = lookup(each.value, "direction", "INGRESS")
  priority             = lookup(each.value, "priority", 1000)
  source_ranges        = lookup(each.value, "source_ranges", [])
  destination_ranges   = lookup(each.value, "destination_ranges", [])
  source_tags          = lookup(each.value, "source_tags", [])
  target_tags          = lookup(each.value, "target_tags", [])
  source_service_accounts = lookup(each.value, "source_service_accounts", [])
  target_service_accounts = lookup(each.value, "target_service_accounts", [])
  denied               = lookup(each.value, "denied", [])
  allowed              = lookup(each.value, "allowed", [])

  dynamic "log_config" {
    for_each = lookup(each.value, "enable_logging", false) ? [1] : []
    content {
      metadata = lookup(each.value, "log_metadata", "INCLUDE_ALL_METADATA")
    }
  }

  depends_on = [google_compute_subnetwork.this]
}

resource "google_compute_router" "this" {
  for_each = var.routers

  name    = each.value.name
  network = google_compute_network.this.name
  region  = each.value.region
  project = var.project_id

  bgp {
    asn = each.value.bgp_asn
    advertise_mode = lookup(each.value, "advertise_mode", "DEFAULT")
    advertised_groups = lookup(each.value, "advertised_groups", [])
    advertised_ip_ranges = lookup(each.value, "advertised_ip_ranges", {})
  }

  dynamic "nats" {
    for_each = lookup(each.value, "nats", {})
    content {
      name = nats.key
      nat_ip_allocate_option = lookup(nats.value, "nat_ip_allocate_option", "AUTO_ONLY")
      
      dynamic "source_subnetwork_ip_ranges_to_nat" {
        for_each = lookup(nats.value, "source_subnetwork_ip_ranges_to_nat", null) != null ? [nats.value.source_subnetwork_ip_ranges_to_nat] : []
        content {
          all = lookup(source_subnetwork_ip_ranges_to_nat.value, "all", false)
          subnetworks = lookup(source_subnetwork_ip_ranges_to_nat.value, "subnetworks", [])
        }
      }

      dynamic "nat_ips" {
        for_each = lookup(nats.value, "nat_ips", [])
        content {
          self_link = nat_ips.value
        }
      }

      log_config {
        enable = lookup(nats.value, "enable_nat_logging", false)
        filter = lookup(nats.value, "nat_log_filter", "ALL")
      }
    }
  }
}

resource "google_compute_route" "this" {
  for_each = var.routes

  name                   = each.value.name
  network               = google_compute_network.this.name
  dest_range            = each.value.dest_range
  next_hop_ip           = lookup(each.value, "next_hop_ip", null)
  next_hop_instance     = lookup(each.value, "next_hop_instance", null)
  next_hop_instance_zone = lookup(each.value, "next_hop_instance_zone", null)
  next_hop_vpn_tunnel   = lookup(each.value, "next_hop_vpn_tunnel", null)
  priority              = lookup(each.value, "priority", 1000)
  tags                  = lookup(each.value, "tags", [])
  project               = var.project_id
}

resource "google_compute_address" "this" {
  for_each = var.external_addresses

  name         = each.value.name
  address_type = lookup(each.value, "address_type", "EXTERNAL")
  region       = lookup(each.value, "region", null)
  description  = lookup(each.value, "description", "")
  project      = var.project_id

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_compute_global_address" "this" {
  for_each = var.global_addresses

  name        = each.value.name
  address_type = lookup(each.value, "address_type", "EXTERNAL")
  description = lookup(each.value, "description", "")
  project     = var.project_id

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_compute_vpn_gateway" "this" {
  for_each = var.vpn_gateways

  name    = each.value.name
  network = google_compute_network.this.name
  region  = each.value.region
  project = var.project_id

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_compute_forwarding_rule" "this" {
  for_each = var.vpn_gateways

  name        = "${each.value.name}-forwarding-rule"
  region      = each.value.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.this["${each.value.name}-ip"].address
  target      = google_compute_vpn_gateway.this[each.key].self_link
  project     = var.project_id
}

resource "google_compute_address" "vpn_gateway_ip" {
  for_each = var.vpn_gateways

  name         = "${each.value.name}-ip"
  address_type = "EXTERNAL"
  region       = each.value.region
  project      = var.project_id
}

resource "google_compute_ha_vpn_gateway" "this" {
  for_each = var.ha_vpn_gateways

  name    = each.value.name
  network = google_compute_network.this.name
  region  = each.value.region
  project = var.project_id

  vpn_interfaces {
    id                     = 0
    ip_range                = google_compute_ha_vpn_gateway_ip_range.this["${each.key}-0"].ip_range
  }

  vpn_interfaces {
    id                     = 1
    ip_range                = google_compute_ha_vpn_gateway_ip_range.this["${each.key}-1"].ip_range
  }

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_compute_ha_vpn_gateway_ip_range" "this" {
  for_each = var.ha_vpn_gateways

  name    = "${each.value.name}-${each.key}"
  region  = each.value.region
  project = var.project_id
}

resource "google_compute_network_peering" "this" {
  for_each = var.network_peerings

  name         = each.key
  network      = google_compute_network.this.self_link
  peer_network = each.value.peer_network
  export_custom_routes   = lookup(each.value, "export_custom_routes", false)
  import_custom_routes   = lookup(each.value, "import_custom_routes", false)
  stack_type            = lookup(each.value, "stack_type", null)

  project = var.project_id
}

resource "google_compute_network_peering_routes_config" "this" {
  for_each = var.network_peerings

  network = google_compute_network.this.name
  peering = google_compute_network_peering.this[each.key].name

  export_custom_routes   = lookup(each.value, "export_custom_routes", false)
  import_custom_routes   = lookup(each.value, "import_custom_routes", false)

  project = var.project_id
}

resource "google_compute_interconnect_attachment" "this" {
  for_each = var.interconnect_attachments

  name                     = each.value.name
  interconnect             = each.value.interconnect
  router                   = google_compute_router.this[each.value.router].name
  region                   = each.value.region
  bandwidth                = each.value.bandwidth
  type                     = each.value.type
  candidate_subnets        = lookup(each.value, "candidate_subnets", [])
  admin_enabled            = lookup(each.value, "admin_enabled", true)
  mtu                      = lookup(each.value, "mtu", 1500)
  project                  = var.project_id

  labels = merge(module.tags.tags, var.labels_override)
}

resource "google_service_networking_connection" "this" {
  for_each = var.service_networking

  network       = google_compute_network.this.name
  service       = each.value.service
  reserved_peering_ranges = each.value.reserved_peering_ranges

  depends_on = [google_compute_subnetwork.this]
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.this.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.this.self_link
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = { for k, v in google_compute_subnetwork.this : k => v.id }
}

output "subnet_self_links" {
  description = "Self links of the subnets"
  value       = { for k, v in google_compute_subnetwork.this : k => v.self_link }
}

output "firewall_rule_ids" {
  description = "IDs of the firewall rules"
  value       = { for k, v in google_compute_firewall.this : k => v.id }
}

output "router_ids" {
  description = "IDs of the routers"
  value       = { for k, v in google_compute_router.this : k => v.id }
}

output "external_addresses" {
  description = "External IP addresses"
  value       = { for k, v in google_compute_address.this : k => v.address }
}

output "global_addresses" {
  description = "Global external IP addresses"
  value       = { for k, v in google_compute_global_address.this : k => v.address }
}

output "vpn_gateway_ids" {
  description = "IDs of the VPN gateways"
  value       = { for k, v in google_compute_vpn_gateway.this : k => v.id }
}
