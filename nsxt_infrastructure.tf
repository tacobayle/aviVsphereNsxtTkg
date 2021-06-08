data "nsxt_policy_transport_zone" "tz" {
  display_name = var.no_access_vcenter.nsxt.transport_zone.name
}

data "nsxt_policy_transport_zone" "tz_nsxt" {
  display_name = var.nsxt.transport_zone.name
}

data "nsxt_policy_tier0_gateway" "tier0" {
  count = length(var.no_access_vcenter.nsxt.tier1s)
  display_name = var.no_access_vcenter.nsxt.tier1s[count.index].tier0
}

data "nsxt_policy_tier0_gateway" "tier0_nsxt" {
  count = length(var.nsxt.nsxt.tier1s)
  display_name = var.nsxt.nsxt.tier1s[count.index].tier0
}

resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  count = length(var.no_access_vcenter.nsxt.tier1s)
  description               = var.no_access_vcenter.nsxt.tier1s[count.index].description
  display_name              = var.no_access_vcenter.nsxt.tier1s[count.index].name
  tier0_path                = data.nsxt_policy_tier0_gateway.tier0[count.index].path
  route_advertisement_types = var.no_access_vcenter.nsxt.tier1s[count.index].route_advertisement_types
}

resource "nsxt_policy_tier1_gateway" "tier1_gw_nsxt" {
  count = length(var.nsxt.nsxt.tier1s)
  description               = var.nsxt.nsxt.tier1s[count.index].description
  display_name              = var.nsxt.nsxt.tier1s[count.index].name
  tier0_path                = data.nsxt_policy_tier0_gateway.tier0_nsxt[count.index].path
  route_advertisement_types = var.nsxt.nsxt.tier1s[count.index].route_advertisement_types
}

resource "time_sleep" "wait_tier1" {
  depends_on = [nsxt_policy_tier1_gateway.tier1_gw]
  create_duration = "10s"
}

resource "time_sleep" "wait_tier1_nsxt" {
  depends_on = [nsxt_policy_tier1_gateway.tier1_gw_nsxt]
  create_duration = "10s"
}

data "nsxt_policy_tier1_gateway" "avi_network_backend_tier1_router_nsxt" {
  depends_on = [time_sleep.wait_tier1_nsxt]
  display_name = var.nsxt.nsxt.network_backend.tier1
}

resource "nsxt_policy_segment" "networkBackend" {
  display_name        = var.nsxt.nsxt.network_backend.name
  connectivity_path   = data.nsxt_policy_tier1_gateway.avi_network_backend_tier1_router_nsxt.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz_nsxt.path
  description         = "Network Segment built by Terraform"
  subnet {
    cidr        = var.nsxt.nsxt.network_backend.cidr
  }
}

//data "nsxt_policy_tier1_gateway" "avi_network_backend_tier1_router" {
//  depends_on = [time_sleep.wait_tier1]
//  display_name = var.nsxt.network_backend.tier1
//}

//data "nsxt_policy_tier1_gateway" "avi_network_mgmt_tier1_router" {
//  depends_on = [time_sleep.wait_tier1]
//  display_name = var.no_access_vcenter.nsxt.network_management.tier1
//}

data "nsxt_policy_tier1_gateway" "avi_network_mgmt_tier1_router_nsxt" {
  depends_on = [time_sleep.wait_tier1_nsxt]
  display_name = var.nsxt.nsxt.network_management.tier1
}

//data "nsxt_policy_tier1_gateway" "avi_network_mgt" {
//  depends_on = [time_sleep.wait_tier1]
//  display_name = var.no_access_vcenter.nsxt.network_management.tier1
//}

data "nsxt_policy_tier1_gateway" "avi_network_vip_tier1_router_nsxt" {
  count = length(var.nsxt.nsxt.networks_data)
  depends_on = [time_sleep.wait_tier1_nsxt]
  display_name = var.nsxt.nsxt.networks_data[count.index].tier1
}

data "nsxt_policy_tier1_gateway" "avi_network_vip_tier1_router_tkg" {
  count = length(var.no_access_vcenter.nsxt.networks_data)
  depends_on = [time_sleep.wait_tier1]
  display_name = var.no_access_vcenter.nsxt.networks_data[count.index].tier1
}

resource "nsxt_policy_segment" "networkVip" {
  count = length(var.nsxt.nsxt.networks_data)
  display_name        = var.nsxt.nsxt.networks_data[count.index].name
  connectivity_path   = data.nsxt_policy_tier1_gateway.avi_network_vip_tier1_router_nsxt[count.index].path
  transport_zone_path = data.nsxt_policy_transport_zone.tz_nsxt.path
  description         = "Network Segment built by Terraform"
  subnet {
    cidr        = var.nsxt.nsxt.networks_data[count.index].defaultGateway
  }
}

resource "nsxt_policy_segment" "networkTkg" {
  count = length(var.no_access_vcenter.nsxt.networks_data)
  display_name        = var.no_access_vcenter.nsxt.networks_data[count.index].name
  connectivity_path   = data.nsxt_policy_tier1_gateway.avi_network_vip_tier1_router_tkg[count.index].path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  description         = "Network Segment built by Terraform"
  subnet {
    cidr        = var.no_access_vcenter.nsxt.networks_data[count.index].defaultGateway
  }
}

resource "nsxt_policy_segment" "networkMgmt" {
  display_name        = var.nsxt.nsxt.network_management.name
  connectivity_path   = data.nsxt_policy_tier1_gateway.avi_network_mgmt_tier1_router_nsxt.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  description         = "Network Segment built by Terraform"
  subnet {
    cidr        = var.nsxt.nsxt.network_management.defaultGateway
  }
}

//resource "nsxt_policy_group" "backend" {
//  display_name = var.backend.nsxtGroup.name
//  description = var.backend.nsxtGroup.description
//
//  criteria {
//    condition {
//      key = "Tag"
//      member_type = "VirtualMachine"
//      operator = "EQUALS"
//      value = var.backend.nsxtGroup.tag
//    }
//  }
//}



//resource "nsxt_policy_segment" "networkMgmt" {
//  display_name        = var.nsxt.management_network.name
//  connectivity_path   = data.nsxt_policy_tier1_gateway.avi_network_mgmt_tier1_router.path
//  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
//  description         = "Network Segment built by Terraform"
//  subnet {
//    cidr        = "${cidrhost(var.nsxt.management_network.cidr, 1)}/${split("/", var.nsxt.management_network.cidr)[1]}"
//  }
//}

//resource "time_sleep" "wait_segment" {
////  depends_on = [nsxt_policy_segment.networkVip, nsxt_policy_segment.networkBackend, nsxt_policy_segment.networkMgmt, nsxt_policy_segment.networkMgt]
//  depends_on = [nsxt_policy_segment.networkTkg]
//  create_duration = "20s"
//}

resource "time_sleep" "wait_segment_nsxt" {
  //  depends_on = [nsxt_policy_segment.networkVip, nsxt_policy_segment.networkBackend, nsxt_policy_segment.networkMgmt, nsxt_policy_segment.networkMgt]
  depends_on = [nsxt_policy_segment.networkBackend, nsxt_policy_segment.networkMgmt, nsxt_policy_segment.networkTkg]
  create_duration = "20s"
}

resource "nsxt_policy_group" "se_no_access" {
  count = (var.no_access_vcenter.nsxt_se_dfw == true ? 1 : 0)
  display_name = "EasyAvi-SE"
  description  = "EasyAvi-SE"
  criteria {
    condition {
      member_type = "VirtualMachine"
      key = "Name"
      operator = "STARTSWITH"
      value = var.no_access_vcenter.se_prefix
    }
  }
}

resource "nsxt_policy_group" "pods_cidr" {
  count = (var.no_access_vcenter.nsxt_se_dfw == true ? 1 : 0)
  display_name = "EasyAvi-Pods_CIDR"
  description  = "EasyAvi-Pods_CIDR"
  criteria {
    ipaddress_expression {
      ip_addresses = ["10.244.0.0/20"]
    }
  }
}

resource "nsxt_policy_nat_rule" "no_nat_se_pods" {
  count = (var.no_access_vcenter.nsxt_se_dfw == true ? 1 : 0)
  display_name         = "EasyAvi-no-nat-se-pods"
  action               = "NO_DNAT"
  source_networks      = ["${cidrhost(no_access_vcenter.serviceEngineGroup[1].data_networks[0].defaultGateway, 0)}/${split("/", no_access_vcenter.serviceEngineGroup[1].data_networks[0].defaultGateway)[1]}"]
  destination_networks = ["10.244.0.0/20"]
  translated_networks  = ["ANY"]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}


data "nsxt_policy_group" "se_nsxt" {
  depends_on = [null_resource.ansible]
  display_name = "${var.nsxt.obj_name_prefix}-ServiceEngines"
}

data "nsxt_policy_group" "controller_nsxt" {
  depends_on = [null_resource.ansible]
  display_name = "${var.nsxt.obj_name_prefix}-ControllerCluster"
}

//
//resource "nsxt_policy_group" "backend" {
//  display_name = var.backend.nsxtGroup.name
//  description = var.backend.nsxtGroup.description
//
//  criteria {
//    condition {
//      key = "Tag"
//      member_type = "VirtualMachine"
//      operator = "EQUALS"
//      value = var.backend.nsxtGroup.tag
//    }
//  }
//}
//
//resource "nsxt_vm_tags" "backend" {
//  count = length(var.backendIps)
//  instance_id = vsphere_virtual_machine.backend[count.index].id
//  tag {
//    tag   = var.backend.nsxtGroup.tag
//  }
//}