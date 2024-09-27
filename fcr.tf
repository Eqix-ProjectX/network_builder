/*##vipin - module to spin up FCR
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


##vipin - to create Azure Service Key 
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
