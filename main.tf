terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
    }
    iosxe = {
      source = "CiscoDevNet/iosxe"
    }
  }
  cloud {

    organization = "EQIX_projectX"

    workspaces {
      name = "network_builder_apac"
    }
  }
}

provider "iosxe" {
  alias    = "vd_pri"
  username = var.username
  password = data.terraform_remote_state.ne.outputs.vd_password
  url      = "https://${data.terraform_remote_state.ne.outputs.ssh_ip_vd}"
}
provider "iosxe" {
  alias    = "vd_sec"
  username = var.username
  password = data.terraform_remote_state.ne.outputs.vd_password_sec
  url      = "https://${data.terraform_remote_state.ne.outputs.ssh_ip_vd_sec}"
}

data "terraform_remote_state" "ne" {
  backend = "remote"
  config = {
    organization = "EQIX_projectX"
    workspaces = {
      name = "ne-apac"
    }
  }
}
data "terraform_remote_state" "bgp" {
  backend = "remote"
  config = {
    organization = "EQIX_projectX"
    workspaces = {
      name = "metal-apac"
    }
  }
}

locals {
  ipv4_vrf_pri   = cidrhost(data.terraform_remote_state.bgp.outputs.vrf_ranges[1], 1)
  ipv4_vrf_sec   = cidrhost(data.terraform_remote_state.bgp.outputs.vrf_ranges_sec[1], 1)
  ipv4_int_pri      = cidrhost(data.terraform_remote_state.bgp.outputs.vrf_ranges[1], 2)
  ipv4_int_sec      = cidrhost(data.terraform_remote_state.bgp.outputs.vrf_ranges_sec[1], 2)
}

# IOS-XE configuration
resource "iosxe_interface_ethernet" "interface_pri" {
  provider                         = iosxe.vd_pri
  type                             = "GigabitEthernet"
  name                             = var.int
  bandwidth                        = var.bw
  description                      = var.int_desc
  shutdown                         = false
  ip_proxy_arp                     = false
  ip_redirects                     = false
  ip_unreachables                  = false
  ipv4_address                     = local.ipv4_int_pri
  ipv4_address_mask                = cidrnetmask("${local.ipv4_int_pri}/${data.terraform_remote_state.bgp.outputs.cidr}")
  snmp_trap_link_status            = true
  logging_event_link_status_enable = true
}
resource "iosxe_interface_ethernet" "interface_sec" {
  provider                         = iosxe.vd_sec
  type                             = "GigabitEthernet"
  name                             = var.int
  bandwidth                        = var.bw
  description                      = var.int_desc
  shutdown                         = false
  ip_proxy_arp                     = false
  ip_redirects                     = false
  ip_unreachables                  = false
  ipv4_address                     = local.ipv4_int_sec
  ipv4_address_mask                = cidrnetmask("${local.ipv4_int_sec}/${data.terraform_remote_state.bgp.outputs.cidr}")
  snmp_trap_link_status            = true
  logging_event_link_status_enable = true
}

resource "iosxe_bgp" "bgp_pri" {
  provider             = iosxe.vd_pri
  asn                  = var.vnf_asn
  log_neighbor_changes = true
}
resource "iosxe_bgp" "bgp_sec" {
  provider             = iosxe.vd_sec
  asn                  = var.vnf_asn
  log_neighbor_changes = true
}

resource "iosxe_bgp_neighbor" "neighbor_pri" {
  provider                = iosxe.vd_pri
  asn                     = var.vnf_asn
  ip                      = local.ipv4_vrf_pri
  remote_as               = data.terraform_remote_state.bgp.outputs.vrf_asn
  description             = var.neighbor_desc_pri
  shutdown                = false
  disable_connected_check = false
  log_neighbor_changes    = true
}

resource "iosxe_bgp_neighbor" "neighbor_sec" {
  provider                = iosxe.vd_sec
  asn                     = var.vnf_asn
  ip                      = local.ipv4_vrf_sec
  remote_as               = data.terraform_remote_state.bgp.outputs.vrf_asn
  description             = var.neighbor_desc_sec
  shutdown                = false
  disable_connected_check = false
  log_neighbor_changes    = true
}

# resource "iosxe_save_config" "write_pri" {
#   provider = iosxe.vd_pri
#   depends_on = [
#     iosxe_bgp.bgp_pri, iosxe_bgp_neighbor.neighbor_pri,
#     iosxe_interface_ethernet.interface_pri
#   ]
# }
# resource "iosxe_save_config" "write_sec" {
#   provider = iosxe.vd_sec
#   depends_on = [
#     iosxe_bgp.bgp_sec, iosxe_bgp_neighbor.neighbor_sec,
#     iosxe_interface_ethernet.interface_sec
#   ]
# }

resource "equinix_fabric_connection" "vd2vrf_pri" {
  name = var.pri_vc
  type = "EVPL_VC"
  redundancy {
    priority = "PRIMARY"
  }
  notifications {
    type   = "ALL"
    emails = var.emails
  }
  bandwidth = 50

  a_side {
    access_point {
      type = "VD"
      virtual_device {
        type = "EDGE"
        uuid = data.terraform_remote_state.ne.outputs.vd_uuid
      }
      interface {
        type = "NETWORK"
        id   = var.int
      }
    }
  }
  z_side {
    service_token {
      uuid = equinix_metal_connection.vrf2vd.service_tokens[0].id
    }
  }
}
resource "equinix_fabric_connection" "vd2vrf_sec" {
  name = var.sec_vc
  type = "EVPL_VC"
  redundancy {
    priority = "SECONDARY"
    group    = one(equinix_fabric_connection.vd2vrf_pri.redundancy).group
  }
  notifications {
    type   = "ALL"
    emails = var.emails
  }
  bandwidth = 50

  a_side {
    access_point {
      type = "VD"
      virtual_device {
        type = "EDGE"
        uuid = data.terraform_remote_state.ne.outputs.vd_uuid_sec
      }
      interface {
        type = "NETWORK"
        id   = var.int
      }
    }
  }
  z_side {
    service_token {
      uuid = equinix_metal_connection.vrf2vd.service_tokens[1].id
    }
  }
}

/*
resource "time_sleep" "wait_2_min" {
  create_duration = "2m"
  depends_on = [
    equinix_fabric_connection.vd2vrf_pri,
    equinix_fabric_connection.vd2vrf_sec
  ]
}
*/

resource "equinix_metal_connection" "vrf2vd" {
  name          = var.connection_name
  project_id    = var.project_id
  metro         = var.metro_code
  redundancy    = "redundant"
  type          = "shared"
  contact_email = join("", var.emails)
  vrfs = [
    data.terraform_remote_state.bgp.outputs.vrf_pri,
    data.terraform_remote_state.bgp.outputs.vrf_sec
  ]
  service_token_type = "z_side"
}

/* commented out portion of BGP peering setup for now -TF not supported-
resource "equinix_metal_virtual_circuit" "peer_pri" {
  project_id = var.project_id
  connection_id = equinix_metal_connection.vrf2vd.id
  port_id       = equinix_metal_connection.vrf2vd.ports[0].id
  vrf_id        = data.terraform_remote_state.bgp.outputs.vrf_pri
  peer_asn      = var.vnf_asn
  subnet        = cidrsubnet(data.terraform_remote_state.bgp.outputs.vrf_ranges[1], 5, 0)
  metal_ip      = local.ipv4_mg_pri
  customer_ip   = local.ipv4_pri
  nni_vlan      = [for z in equinix_fabric_connection.vd2vrf_pri.z_side : [for ap in z.access_point : [for lp in ap.link_protocol : lp.vlan_tag]]][0]
  depends_on    = [time_sleep.wait_2_min,
  equinix_fabric_connection.vd2vrf_pri]
}
resource "equinix_metal_virtual_circuit" "peer_sec" {
  project_id         = var.project_id
  connection_id = equinix_metal_connection.vrf2vd.id
  port_id    = equinix_metal_connection.vrf2vd.ports[1].id
  vrf_id     = data.terraform_remote_state.bgp.outputs.vrf_sec
  peer_asn   = var.vnf_asn
  subnet     = cidrsubnet(data.terraform_remote_state.bgp.outputs.vrf_ranges_sec[1], 5, 0)
  metal_ip = local.ipv4_mg_sec
  customer_ip = local.ipv4_sec
  nni_vlan = [for z in equinix_fabric_connection.vd2vrf_pri.z_side : [for ap in z.access_point : [for lp in ap.link_protocol : lp.vlan_tag]]][0]
  depends_on = [time_sleep.wait_2_min]
}
*/