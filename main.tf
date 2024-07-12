terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
    }
  }
}

module "ne" {
  source             = "github.com/Eqix-ProjectX/terraform-equinix-networkedge-vnf/"
  core_count         = var.core_count
  metro_code         = var.metro_code
  notifications      = var.notifications
  package_code       = var.package_code
  account_number     = var.account_number
  sec_account_number = var.sec_account_number
  sec_metro_code     = var.sec_metro_code
  type_code          = var.type_code
  ver                = var.ver
  username           = var.username
  key_name           = var.key_name
  acl_template_id    = var.acl_template_id
}

# netmiko portion for restconf readiness
data "equinix_network_device" "vd_pri" {
  name = "vd-${var.metro_code}-${var.username}-pre"
  depends_on = [module.ne]
}
data "equinix_network_device" "vd_sec" {
  name = "vd-${var.sec_metro_code}-${var.username}-sec"
  depends_on = [module.ne]
}
data "equinix_metal_device" "instance" {
  project_id = var.project_id
  hostname  = "metal-${var.metro}-node-1"
  depends_on = [module.instance]
}
locals {
  config = <<-EOF
  from netmiko import ConnectHandler

  pri = {
    'device_type': 'cisco_xe',
    'host'       : '${data.equinix_network_device.vd_pri.ssh_ip_address}',
    'username'   : '${var.username}',
    'password'   : '${data.equinix_network_device.vd_pri.vendor_configuration.adminPassword}'
  }

  sec = {
    'device_type': 'cisco_xe',
    'host'       : '${data.equinix_network_device.vd_sec.ssh_ip_address}',
    'username'   : '${var.username}',
    'password'   : '${data.equinix_network_device.vd_sec.vendor_configuration.adminPassword}'
  }

  ha = [pri, sec]

  for i in ha:
    net_connect = ConnectHandler(**i)
    config_commands = [
      'ip http secure-server',
      'restconf'
    ]
    output = net_connect.send_config_set(config_commands)
    print(output)
  EOF
}
locals {
  ssh_private_key = base64decode(var.private_key)
}

resource "null_resource" "cisco" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
      host        = data.equinix_metal_device.instance.access_public_ipv4
    }

    inline = [
      "apt install python3-pip -y",
      "y",
      "pip install netmiko",
      "y",
      "cat << EOF > ~/restconf.py\n${local.config}\nEOF",
      "python3 restconf.py"
    ]
  }
}

# IOS-XE configuration
provider "iosxe" {
  alias    = "vd_pri"
  username = "${var.username}"
  password = "${data.equinix_network_device.vd_pri.vendor_configuration.adminPassword}"
  url      = "https://${data.equinix_network_device.vd_pri.ssh_ip_address}"
}
provider "iosxe" {
  alias    = "vd_sec"
  username = "${var.username}"
  password = "${data.equinix_network_device.vd_sec.vendor_configuration.adminPassword}"
  url      = "https://${data.equinix_network_device.vd_sec.ssh_ip_address}"
}

resource "iosxe_interface_ethernet" "interface" {
  type                           = "GigabitEthernet"
  name                           = var.int
  bandwidth                      = var.bw
  description                    = var.int_desc
  shutdown                       = false
  ip_proxy_arp                   = false
  ip_redirects                   = false
  ip_unreachables                = false
  ipv4_address                   = cidrhost("${var.network_range}/${var.cidr}", 3)
  ipv4_address_mask              = var.cidr
  snmp_trap_link_status            = true
  logging_event_link_status_enable = true
}

resource "iosxe_bgp" "bgp" {
  asn                  = var.vnf_asn
  log_neighbor_changes = true
}

resource "iosxe_bgp_address_family_ipv4" "ipv4" {
  asn                   = var.vnf_asn
  af_name               = "unicast"
  ipv4_unicast_redistribute_connected = true
  ipv4_unicast_redistribute_static = true  
}

resource "iosxe_bgp_ipv4_unicast_neighbor" "neighbor" {
  asn                   = var.vrf_asn
  ip                    = cidrhost("${var.network_range}/${var.cidr}", 2)
  activate                = true
  soft_reconfiguration = "inbound"
}