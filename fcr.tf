/*
##vipin - module to spin up FCR
data "terraform_remote_state" "fcr_id" {
  backend = "remote"

  config = {
    organization = "EQIX_projectX"
    workspaces = {
      name = "network-apac"
    }
  }
}

##vipin - to create Layer2 connection from FCR to AWS 
resource "equinix_fabric_connection" "L2_FCRSG_to_AWS" {
  name = "L2_FCRSG_to_AWS"
  type = "IP_VC"
  notifications {
    type   = "ALL"
    emails = [var.email]
  }
  bandwidth = var.FCRtoAWSspeed
  order {
    purchase_order_number = var.purchase_order_number
  }
  a_side {
    access_point {
      type = "CLOUD_ROUTER"
      router {
        uuid = data.terraform_remote_state.fcr_id.outputs.fcr_id
        //uuid = module.FCRcreation.fabric_cloud_router_id
      }

    }
  }

  z_side {
    access_point {
      type               = "SP"
      authentication_key = var.authentication_key
      seller_region      = var.seller_region
      profile {
        type = "L2_PROFILE"
        uuid = var.profile_uuid
      }
      location {
        metro_code = var.awslocation
      }
    }
  }
}

#vipin - to fecth the AWS Dx connection id
locals {


  z_side_list = [
    for z in equinix_fabric_connection.L2_FCRSG_to_AWS.z_side : 
    tolist(z.access_point)[0]
   
  ]

    provider_connection_ids = [
    for access_point in [
      for z in equinix_fabric_connection.L2_FCRSG_to_AWS.z_side : tolist(z.access_point)[0]
    ] : access_point.provider_connection_id
  ]  
}

#vipin - to accept the AWS Dx connection 
resource "aws_dx_connection_confirmation" "ToAccepttheDxconnectioninAWSside" {
  connection_id = local.provider_connection_ids[0]
}

#vipin - to fetch the VLAN ID of AWS Dx connection 
locals {
    vlan_tags = flatten([
    for z in equinix_fabric_connection.L2_FCRSG_to_AWS.z_side : [
      for ap in z.access_point : [
        for lp in ap.link_protocol : lp.vlan_tag
      ]
    ]
  ])

    create_resource = length(local.vlan_tags) > 0
}

data "aws_dx_connection" "tofetchVLANID" {
  depends_on = [ equinix_fabric_connection.L2_FCRSG_to_AWS ]
  name = "L2_FCRSG_to_AWS"
}

output "vlan_id" {
value = data.aws_dx_connection.tofetchVLANID.vlan_id
}

#vipin - to create Layer 3 on AWS VIF 

resource "aws_dx_private_virtual_interface" "Create_AWS_SG_PrivateVIF" {
  depends_on = [aws_dx_connection_confirmation.ToAccepttheDxconnectioninAWSside ]
  connection_id    = local.provider_connection_ids[0] 
  name             = "AWS_VIF_Creation_SG"
  vlan             = data.aws_dx_connection.tofetchVLANID.vlan_id
  address_family   = "ipv4"
  bgp_asn          = 24116
  bgp_auth_key     = "XXYYFFDDCC"
  amazon_address   = "192.168.1.2/30"
  customer_address = "192.168.1.1/30"
  mtu              = 1500
  vpn_gateway_id   = "vgw-09be1bd5f63e75f5c"
} 

#vipin - to create Layer 3 on BGP 
resource "equinix_fabric_routing_protocol" "L3_FCRSG_to_AWS_Equinixside" {
  connection_uuid = equinix_fabric_connection.L2_FCRSG_to_AWS.id
  type            = "DIRECT"
  name            = "L3_FCRSG_to_AWS_Equinixside"
  direct_ipv4 {
    equinix_iface_ip = "192.168.1.1/30"

  }
}

resource "equinix_fabric_routing_protocol" "L3_FCRSG_to_AWS_AWSside" {
  depends_on = [
    equinix_fabric_routing_protocol.L3_FCRSG_to_AWS_Equinixside
  ]
  connection_uuid = equinix_fabric_connection.L2_FCRSG_to_AWS.id
  type            = "BGP"
  customer_asn    = 64520
  name            = "L3_FCRSG_to_AWS_AWSside"
  bgp_auth_key    = "XXYYFFDDCC"
  bgp_ipv4 {
    customer_peer_ip = "192.168.1.2"
    enabled          = true
  }

}

*/


##vipin - to create Azure Service Key 
/*
resource "azurerm_express_route_circuit" "ERSkey_Creation_process" {
  name                  = var.ERCircuitName
  resource_group_name   = var.Azureresourcegroupname
  location              = var.Azurelocation
  service_provider_name = "Equinix"
  peering_location      = var.Azurepeeringlocation
  bandwidth_in_mbps     = var.ERbandwidth

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }

  tags = {
    environment = "var.environment"
  }
}

##vipin - to create Layer2 connection from FCR to Azure
resource "equinix_fabric_connection" "L2_FCRSV_to_Azure" {
  name = "L2_FCRSV_to_Azure"
  type = "IP_VC"
  notifications {
    type   = "ALL"
    emails = [var.email]
  }
  bandwidth = var.FCRtoAzurespeed
  order {
    purchase_order_number = var.purchase_order_number
  }
  a_side {
    access_point {
      type = "CLOUD_ROUTER"
      router {
        uuid = data.terraform_remote_state.fcr_id.outputs.fcr_id
      }

    }
  }

  z_side {
    access_point {
      type               = "SP"
      authentication_key = azurerm_express_route_circuit.ERSkey_Creation_process.service_key
      peering_type       = "PRIVATE"
      profile {
        type = "L2_PROFILE"
        uuid = "a1390b22-bbe0-4e93-ad37-85beef9d254d"
      }
      location {
        metro_code = var.Azuremetrocode
      }
    }
  }
}
*/