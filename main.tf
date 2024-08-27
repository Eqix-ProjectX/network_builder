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

# data "equinix_network_device" "vd_pri" {
#   name = "vd-${var.metro_code}-${var.username}-pri"
# }
# data "equinix_network_device" "vd_sec" {
#   name = "vd-${var.sec_metro_code}-${var.username}-sec"
# }
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
  ipv4_mg_pri = cidrhost("${data.terraform_remote_state.bgp.outputs.network_range_pri}/${data.terraform_remote_state.bgp.outputs.cidr}", 1)
}
locals {
  ipv4_mg_sec = cidrhost("${data.terraform_remote_state.bgp.outputs.network_range_sec}/${data.terraform_remote_state.bgp.outputs.cidr}", 1)
}
locals {
  ipv4_pri1 = cidrhost("${data.terraform_remote_state.bgp.outputs.network_range_pri}/${data.terraform_remote_state.bgp.outputs.cidr}", 2)
}
locals {
  ipv4_pri2 = cidrhost("${data.terraform_remote_state.bgp.outputs.network_range_pri}/${data.terraform_remote_state.bgp.outputs.cidr}", 3)
}
locals {
  ipv4_sec1 = cidrhost("${data.terraform_remote_state.bgp.outputs.network_range_sec}/${data.terraform_remote_state.bgp.outputs.cidr}", 2)
}
locals {
  ipv4_sec2 = cidrhost("${data.terraform_remote_state.bgp.outputs.network_range_sec}/${data.terraform_remote_state.bgp.outputs.cidr}", 3)
}

# IOS-XE configuration
resource "iosxe_interface_ethernet" "interface_pri1" {
  provider                         = iosxe.vd_pri
  type                             = "GigabitEthernet"
  name                             = var.int_pri
  bandwidth                        = var.bw
  description                      = var.int_desc_pri
  shutdown                         = false
  ip_proxy_arp                     = false
  ip_redirects                     = false
  ip_unreachables                  = false
  ipv4_address                     = local.ipv4_pri1
  ipv4_address_mask                = cidrnetmask("${local.ipv4_pri1}/${data.terraform_remote_state.bgp.outputs.cidr}")
  snmp_trap_link_status            = true
  logging_event_link_status_enable = true
}
resource "iosxe_interface_ethernet" "interface_sec1" {
  provider                         = iosxe.vd_pri
  type                             = "GigabitEthernet"
  name                             = var.int_sec
  bandwidth                        = var.bw
  description                      = var.int_desc_sec
  shutdown                         = false
  ip_proxy_arp                     = false
  ip_redirects                     = false
  ip_unreachables                  = false
  ipv4_address                     = local.ipv4_sec1
  ipv4_address_mask                = cidrnetmask("${local.ipv4_sec1}/${data.terraform_remote_state.bgp.outputs.cidr}")
  snmp_trap_link_status            = true
  logging_event_link_status_enable = true
}

resource "iosxe_interface_ethernet" "interface_pri2" {
  provider                         = iosxe.vd_sec
  type                             = "GigabitEthernet"
  name                             = var.int_pri
  bandwidth                        = var.bw
  description                      = var.int_desc_pri
  shutdown                         = false
  ip_proxy_arp                     = false
  ip_redirects                     = false
  ip_unreachables                  = false
  ipv4_address                     = local.ipv4_pri2
  ipv4_address_mask                = cidrnetmask("${local.ipv4_pri2}/${data.terraform_remote_state.bgp.outputs.cidr}")
  snmp_trap_link_status            = true
  logging_event_link_status_enable = true
}
resource "iosxe_interface_ethernet" "interface_sec2" {
  provider                         = iosxe.vd_sec
  type                             = "GigabitEthernet"
  name                             = var.int_sec
  bandwidth                        = var.bw
  description                      = var.int_desc_sec
  shutdown                         = false
  ip_proxy_arp                     = false
  ip_redirects                     = false
  ip_unreachables                  = false
  ipv4_address                     = local.ipv4_sec2
  ipv4_address_mask                = cidrnetmask("${local.ipv4_sec2}/${data.terraform_remote_state.bgp.outputs.cidr}")
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

resource "iosxe_bgp_neighbor" "neighbor_pri1" {
  provider                = iosxe.vd_pri
  asn                     = var.vnf_asn
  ip                      = local.ipv4_mg_pri
  remote_as               = data.terraform_remote_state.bgp.outputs.vrf_asn
  description             = var.neighbor_desc_pri
  shutdown                = false
  disable_connected_check = false
  log_neighbor_changes    = true
}
resource "iosxe_bgp_neighbor" "neighbor_sec1" {
  provider                = iosxe.vd_pri
  asn                     = var.vnf_asn
  ip                      = local.ipv4_mg_sec
  remote_as               = data.terraform_remote_state.bgp.outputs.vrf_asn
  description             = var.neighbor_desc_sec
  shutdown                = false
  disable_connected_check = false
  log_neighbor_changes    = true
}
resource "iosxe_bgp_neighbor" "neighbor_pri2" {
  provider                = iosxe.vd_sec
  asn                     = var.vnf_asn
  ip                      = local.ipv4_mg_pri
  remote_as               = data.terraform_remote_state.bgp.outputs.vrf_asn
  description             = var.neighbor_desc_pri
  shutdown                = false
  disable_connected_check = false
  log_neighbor_changes    = true
}
resource "iosxe_bgp_neighbor" "neighbor_sec2" {
  provider                = iosxe.vd_sec
  asn                     = var.vnf_asn
  ip                      = local.ipv4_mg_sec
  remote_as               = data.terraform_remote_state.bgp.outputs.vrf_asn
  description             = var.neighbor_desc_sec
  shutdown                = false
  disable_connected_check = false
  log_neighbor_changes    = true
}

resource "iosxe_save_config" "write_pri" {
  provider = iosxe.vd_pri
}
resource "iosxe_save_config" "write_sec" {
  provider = iosxe.vd_sec
}

resource "equinix_fabric_connection" "vd2mg_pri" {
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
  # order {
  #   purchase_order_number = "1-323292"
  # }
  a_side {
    access_point {
      type = "VD"
      virtual_device {
        type = "EDGE"
        uuid = data.terraform_remote_state.ne.outputs.vd_uuid
      }
      interface {
        type = "NETWORK"
        id = 7
      }
    }
  }
  z_side {
    service_token {
      uuid = data.terraform_remote_state.bgp.outputs.connection_token_pri
    }
  }
}

resource "equinix_fabric_connection" "vd2mg_sec" {
  name = var.sec_vc
  type = "EVPL_VC"
  redundancy {
    priority = "SECONDARY"
    group = one(equinix_fabric_connection.vd2mg_pri.redundancy).group
  }
  notifications {
    type   = "ALL"
    emails = var.emails
  }
  bandwidth = 50
  # order {
  #   purchase_order_number = "1-323292"
  # }
  a_side {
    access_point {
      type = "VD"
      virtual_device {
        type = "EDGE"
        uuid = data.terraform_remote_state.ne.outputs.vd_uuid_sec
      }
      interface {
        type = "NETWORK"
        id = 7
      }
    }
  }
  z_side {
    service_token {
      uuid = data.terraform_remote_state.bgp.outputs.connection_token_sec
  }
  }
}