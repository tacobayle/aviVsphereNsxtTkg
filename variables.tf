variable "vsphere_username" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

variable "nsx_username" {}
variable "nsx_password" {}
variable "nsx_server" {}

variable "avi_username" {}
variable "avi_password" {}

variable "contentLibrary" {
  default = {
    name = "Avi Content Library"
    description = "Avi Content Library"
    avi = "/home/christoph/Downloads/controller-20.1.4-9087.ova"
    ubuntu = "/home/christoph/Downloads/bionic-server-cloudimg-amd64.ova"
  }
}

variable "controller" {
  default = {
    cpu = 8
    memory = 24768
    disk = 128
    count = "1"
    wait_for_guest_net_timeout = 2
    environment = "VMWARE"
    mgmt_ip = "10.15.3.201"
    mgmt_mask = "255.255.255.0"
    default_gw = "10.15.3.1"
    dns = ["172.18.0.15"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    floatingIp = "1.1.1.1"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/.creds.json"
  }
}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 24
    public_key_path = "~/.ssh/id_rsa/ubuntu-bionic-18.04-cloudimg-template.key.pub"
    private_key_path = "~/.ssh/id_rsa/ubuntu-bionic-18.04-cloudimg-template.key"
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    aviSdkVersion = "18.2.9"
    ipCidr = "10.15.3.210/24"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    defaultGw = "10.15.3.1"
    dnsMain = "172.18.0.15"
    username = "ubuntu"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    aviConfigureTag = "v4.52"
  }
}

//variable "backend" {
//  type = map
//  default = {
//    cpu = 2
//    memory = 4096
//    disk = 20
//    count = 2
//    wait_for_guest_net_routable = "false"
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
//  }
//}


//variable "client" {
//  type = map
//  default = {
//    cpu = 2
//    memory = 4096
//    disk = 20
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
//    count = 1
//  }
//}

variable "no_access_vcenter" {
  default = {
    name = "cloudNoAccess"
    dhcp_enabled = false
    nsxt = {
      server = "10.8.0.20"
      transport_zone = {
        name = "N2_TZ_nested_nsx-overlay"
      }
      tier1s = [
        {
          name = "N2-T1_AVI"
          description = "N2-T1_AVI"
          route_advertisement_types = [
            "TIER1_STATIC_ROUTES",
            "TIER1_CONNECTED",
            "TIER1_LB_VIP"]
          # TIER1_LB_VIP needs to be tested - 20.1.3 TOI
          tier0 = "N2_T0"
        }
      ]
      network_management = {
        name = "N2-T1_Segment-Mgmt-10.15.3.0-24"
        tier1 = "N2-T1_AVI"
        cidr = "10.15.3.0/24"
      }
      network_vip = {
        name = "N2-T1_Segment-VIP-A_10.15.4.0-24"
        tier1 = "N2-T1_AVI"
        cidr = "10.15.4.0/24"
      }
    }
    vcenter = {
      dc = "N2-DC"
      server = "10.8.0.10"
      cluster = "N2-Cluster1"
      datastore = "vsanDatastore"
      resource_pool = "N2-Cluster1/Resources"
      folderAvi = "Avi-Controllers"
    }
    domains = [
      {
        name = "altherr.info"
      }
    ]
    network_management = {
      name = "N2-T1_Segment-Mgmt-10.15.3.0-24" # for SE IP static allocation
      cidr = "10.15.3.0/24" # for SE IP static allocation
      ipStartPool = 21 # for SE IP static allocation. keep integer.
      defaultGateway = 1
    }
    network_vip = {
      name = "N2-T1_Segment-VIP-A_10.15.4.0-24"
      cidr = "10.15.4.0/24"
      type = "V4"
      ipStartPool = "11"
      ipEndPool = "50"
      exclude_discovered_subnets = "true"
      vcenter_dvs = "true"
      dhcp_enabled = "false"
      defaultGateway = 1
    }
//    network_backend = {
//      name = "avi-backend"
//      cidr = "10.1.2.0/24"
//      networkRangeBegin = "11" # for NSX-T segment
//      networkRangeEnd = "50" # for NSX-T segment
//    }
    serviceEngineGroup = [
      {
        name = "Default-Group"
        numberOfSe = 2
        folder = "Avi - SE - Default-Group"
        dhcp = false
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = "1"
        disk_per_se = "25"
        vcpus_per_se = "1"
        cpu_reserve = "false"
        memory_per_se = "1024"
        mem_reserve = "false"
        extra_shared_config_memory = "0"
      },
//      {
//        name = "seGroupGslb"
//        numberOfSe = 1
//
//
//        ha_mode = "HA_MODE_SHARED"
//        min_scaleout_per_vs = "1"
//        disk_per_se = "25"
//        vcpus_per_se = "2"
//        cpu_reserve = "false"
//        memory_per_se = "1024"
//        mem_reserve = "false"
//        extra_shared_config_memory = "0"
//      }
    ]
//    pool = {
//      name = "pool1"
//      lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
//    }
//    pool_opencart = {
//      name = "pool2-opencart"
//      lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
//    }
//    virtualservices = {
//      http = [
//        {
//          name = "app1"
//          pool_ref = "pool1"
//          services: [
//            {
//              port = 80
//              enable_ssl = "false"
//            },
//            {
//              port = 443
//              enable_ssl = "true"
//            }
//          ]
//        },
//        {
//          name = "opencart"
//          pool_ref = "pool2-opencart"
//          services: [
//            {
//              port = 80
//              enable_ssl = "false"
//            },
//            {
//              port = 443
//              enable_ssl = "true"
//            }
//          ]
//        }
//      ]
//      dns = [
//        {
//          name = "dns"
//          services: [
//            {
//              port = 53
//            }
//          ]
//        },
//        {
//          name = "gslb"
//          services: [
//            {
//              port = 53
//            }
//          ]
//          se_group_ref: "seGroupGslb"
//        }
//      ]
//    }
  }
}

