variable "vsphere_username" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

variable "nsx_username" {}
variable "nsx_password" {}
variable "nsx_server" {}

variable "avi_username" {}
variable "avi_password" {}

variable "nsxt" {}

variable "vcenter_credentials" {}

//variable "contentLibrary" {
//  default = {
//    name = "Avi Content Library"
//    description = "Avi Content Library"
//    avi = "/home/christoph/Downloads/controller-20.1.4-9087.ova"
//    ubuntu = "/home/christoph/Downloads/bionic-server-cloudimg-amd64.ova"
//  }
//}

//variable "contentLibrary" {
//  default = {
//    name = "CL_tmp_avi"
//    description = "CL_tmp_avi"
//    avi = "/home/christoph/Downloads/controller-20.1.4-9087.ova"
//    ubuntu = "/home/christoph/Downloads/bionic-server-cloudimg-amd64.ova"
//  }
//}
//variable "controller" {
//  default = {
//    cpu = 8
//    memory = 24768
//    disk = 128
//    count = "1"
//    wait_for_guest_net_timeout = 2
//    environment = "VMWARE"
//    mgmt_ip = "10.15.3.201"
//    mgmt_mask = "255.255.255.0"
//    default_gw = "10.15.3.1"
//    dns = ["172.18.0.15"]
//    ntp = ["95.81.173.155", "188.165.236.162"]
//    floatingIp = "1.1.1.1"
//    from_email = "avicontroller@avidemo.fr"
//    se_in_provider_context = "false"
//    tenant_access_to_provider_se = "true"
//    tenant_vrf = "false"
//    aviCredsJsonFile = "~/.creds.json"
//  }
//}

variable "jump" {
  type = map
  default = {
//    name = "jump"
    cpu = 2
    memory = 4096
    disk = 24
    public_key_path = "~/.ssh/id_rsa/ubuntu-bionic-18.04-cloudimg-template.key.pub"
    private_key_path = "~/.ssh/id_rsa/ubuntu-bionic-18.04-cloudimg-template.key"
    wait_for_guest_net_routable = "false"
//    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    aviSdkVersion = "18.2.9"
//    ipCidr = "10.15.3.210/24"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
//    defaultGw = "10.15.3.1"
//    dnsMain = "172.18.0.15"
    username = "ubuntu"
  }
}

variable "backend" {
  default = {
    cpu = 1
    memory = 2048
    disk = 10
//    network = "N1-T1_Segment-Backend_10.7.6.0-24"
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
//    defaultGw = "10.15.6.1"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
    username = "ubuntu"
//    dnsMain = "172.18.0.15"
//    dnsSec = "10.206.8.131"
//    subnetMask = "/24"
//    nsxtGroup = {
//      name = "n1-avi-backend"
//      description = "Created by TF - For Avi Build"
//      tag = "n1-avi-backend"
//    }
  }
}

//variable "backendIps" {
//  type = list
//  default = ["10.15.6.10", "10.15.6.11", "10.15.6.12"]
//}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    aviConfigureTag = "v5.49"
    aviPbAbsentUrl = "https://github.com/tacobayle/ansiblePbAviAbsent"
    aviPbAbsentTag = "v1.51"
    nsxtConfigureDfwUrl = "https://github.com/tacobayle/ansibleNsxtConfigureDfw"
    nsxtConfigureDfwTag = "v1.02"
    NsxtModuleUrl = "https://github.com/vmware/ansible-for-nsxt"
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

//variable "nsxt" {
//  default = {
//    name = "cloudNsxt"
//    dhcp_enabled = "false"
//    obj_name_prefix = "AVINSXT"
//    domains = [
//      {
//        name = "nsxt.altherr.info"
//      }
//    ]
//    nsxt = {
//      transport_zone = {
//        name = "N2_TZ_nested_nsx-overlay"
//      }
//      tier1s = [
//        {
//          name = "N2-T1_AVI_1"
//          description = "N2-T1_AVI_1"
//          route_advertisement_types = [
//            "TIER1_STATIC_ROUTES",
//            "TIER1_CONNECTED",
//            "TIER1_LB_VIP"]
//          # TIER1_LB_VIP needs to be tested - 20.1.3 TOI
//          tier0 = "N2_T0"
//        },
//        {
//          name = "N2-T1_AVI_2"
//          description = "N2-T1_AVI_2"
//          route_advertisement_types = [
//            "TIER1_STATIC_ROUTES",
//            "TIER1_CONNECTED",
//            "TIER1_LB_VIP"]
//          # TIER1_LB_VIP needs to be tested - 20.1.3 TOI
//          tier0 = "N2_T0"
//        }
//      ]
//      network_backend = {
//        name = "N2-T1_Segment-Backend_10.15.6.0-24"
//        tier1 = "N2-T1_AVI_1"
//        cidr = "10.15.6.1/24"
//      }
//      network_management = {
//        name = "N2-T1_Segment-Mgmt-10.15.3.0-24"
//        tier1 = "N2-T1_AVI_1"
//        defaultGateway = "10.15.3.1/24"
//      }
//      networks_data = [
//        {
//          name = "N2-T1_Segment-VIP-A_10.15.4.0-24"
//          tier1 = "N2-T1_AVI_1"
//          defaultGateway = "10.15.4.1/24"
//        },
//        {
//          name = "N2-T1_Segment-VIP-B_10.15.5.0-24"
//          tier1 = "N2-T1_AVI_2"
//          defaultGateway = "10.15.5.1/24"
//        }
//      ]
//    }
//    vcenter = {
//      name = "vcenter-server-A"
//      dc = "N2-DC"
//      cluster = "N2-Cluster1"
//      datastore = "vsanDatastore"
//      resource_pool = "N2-Cluster1/Resources"
//      folderAvi = "Avi-Controllers"
//      folderApp = "Avi-Apps"
//      content_library = {
//        name = "Avi SE Content Library"
//        description = "TF built - Avi SE Content Library"
//      }
//    }
//    vcenters = [
//      {
//        name = "vcenter-server-A"
//        dc = "N2-DC"
//        cluster = "N2-Cluster1"
//        datastore = "vsanDatastore"
//        vsphere_server = ""
//        content_library = {
//          name = "Avi SE Content Library"
//        }
//      }
//    ]
//    network_management = {
//      name = "N2-T1_Segment-Mgmt-10.15.3.0-24"
//      tier1 = "N2-T1_AVI_1"
//      defaultGateway = "10.15.3.1/24"
//      ipStartPool = "11"
//      ipEndPool = "50"
//      type = "V4"
//      dhcp_enabled = "no"
//      exclude_discovered_subnets = "true"
//      vcenter_dvs = "true"
//    }
//    networks_data = [
//      {
//        name = "N2-T1_Segment-VIP-A_10.15.4.0-24"
//        tier1 = "N2-T1_AVI_1"
//        defaultGateway = "10.15.4.1/24"
//        ipStartPool = "11"
//        ipEndPool = "50"
//      },
//      {
//        name = "N2-T1_Segment-VIP-B_10.15.5.0-24"
//        tier1 = "N2-T1_AVI_2"
//        defaultGateway = "10.15.5.1/24"
//        ipStartPool = "11"
//        ipEndPool = "50"
//      }
//    ]
//    network_backend = {
//      name = "N2-T1_Segment-Backend_10.15.6.0-24"
//      tier1 = "N2-T1_AVI_1"
//    }
//    serviceEngineGroup = [
//      {
//        name = "Default-Group"
//        ha_mode = "HA_MODE_SHARED"
//        min_scaleout_per_vs = 2
//        buffer_se = 1
//        extra_shared_config_memory = 0
//        vcenter_folder = "Avi-SE-Default-Group"
//        vcpus_per_se = 1
//        memory_per_se = 2048
//        disk_per_se = 25
//        realtime_se_metrics = {
//          enabled = true
//          duration = 0
//        }
//      },
//      {
//        name = "seGroupCpuAutoScale"
//        ha_mode = "HA_MODE_SHARED"
//        min_scaleout_per_vs = 1
//        max_scaleout_per_vs = 2
//        max_cpu_usage = 70
//        #vs_scaleout_timeout = 30
//        buffer_se = 0
//        extra_shared_config_memory = 0
//        vcenter_folder = "Avi-SE-Autoscale"
//        vcpus_per_se = 1
//        memory_per_se = 1024
//        disk_per_se = 25
//        auto_rebalance = true
//        auto_rebalance_interval = 30
//        auto_rebalance_criteria = [
//          "SE_AUTO_REBALANCE_CPU"
//        ]
//        realtime_se_metrics = {
//          enabled = true
//          duration = 0
//        }
//      },
//      {
//        name = "seGroupGslb"
//        ha_mode = "HA_MODE_SHARED"
//        min_scaleout_per_vs = 1
//        buffer_se = 0
//        extra_shared_config_memory = 2000
//        vcenter_folder = "Avi-SE-GSLB"
//        vcpus_per_se = 2
//        memory_per_se = 8192
//        disk_per_se = 25
//        realtime_se_metrics = {
//          enabled = true
//          duration = 0
//        }
//      }
//    ]
//    httppolicyset = [
//      {
//        name = "http-request-policy-app3-content-switching-nsxt"
//        http_request_policy = {
//          rules = [
//            {
//              name = "Rule 1"
//              match = {
//                path = {
//                  match_criteria = "CONTAINS"
//                  match_str = [
//                    "hello",
//                    "world"]
//                }
//              }
//              rewrite_url_action = {
//                path = {
//                  type = "URI_PARAM_TYPE_TOKENIZED"
//                  tokens = [
//                    {
//                      type = "URI_TOKEN_TYPE_STRING"
//                      str_value = "index.html"
//                    }
//                  ]
//                }
//                query = {
//                  keep_query = true
//                }
//              }
//              switching_action = {
//                action = "HTTP_SWITCHING_SELECT_POOL"
//                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200"
//                pool_ref = "/api/pool?name=pool1-hello-nsxt"
//              }
//            },
//            {
//              name = "Rule 2"
//              match = {
//                path = {
//                  match_criteria = "CONTAINS"
//                  match_str = [
//                    "avi"]
//                }
//              }
//              rewrite_url_action = {
//                path = {
//                  type = "URI_PARAM_TYPE_TOKENIZED"
//                  tokens = [
//                    {
//                      type = "URI_TOKEN_TYPE_STRING"
//                      str_value = ""
//                    }
//                  ]
//                }
//                query = {
//                  keep_query = true
//                }
//              }
//              switching_action = {
//                action = "HTTP_SWITCHING_SELECT_POOL"
//                status_code = "HTTP_LOCAL_RESPONSE_STATUS_CODE_200"
//                pool_ref = "/api/pool?name=pool2-avi-nsxt"
//              }
//            },
//          ]
//        }
//      }
//    ]
//    pools = [
//      {
//        name = "pool1-hello-nsxt"
//        lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
//      },
//      {
//        name = "pool2-avi-nsxt"
//        application_persistence_profile_ref = "System-Persistence-Client-IP"
//        default_server_port = 8080
//      }
//    ]
//    pool_nsxt_group = {
//      name = "pool3BasedOnNsxtGroup"
//      lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
//      nsxt_group_name = "n1-avi-backend"
//    }
//    virtualservices = {
//      http = [
//        {
//          name = "app1-hello-world-nsxt"
//          pool_ref = "pool1-hello-nsxt"
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
//          name = "app2-avi-nsxt"
//          pool_ref = "pool2-avi-nsxt"
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
//          name = "app3-content-switching-nsxt"
//          pool_ref = "pool2-avi-nsxt"
//          http_policies = [
//            {
//              http_policy_set_ref = "/api/httppolicyset?name=http-request-policy-app3-content-switching-nsxt"
//              index = 11
//            }
//          ]
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
//          name = "app4-se-cpu-auto-scale-nsxt"
//          pool_ref = "pool1-hello-nsxt"
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
//          se_group_ref: "seGroupCpuAutoScale"
//        },
//        {
//          name = "app5-nsxtGroupBased"
//          pool_ref = "pool3BasedOnNsxtGroup"
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
//      ]
//      dns = [
//        {
//          name = "app6-dns"
//          services: [
//            {
//              port = 53
//            }
//          ]
//        },
//        {
//          name = "app7-gslb"
//          services: [
//            {
//              port = 53
//            }
//          ]
//          se_group_ref: "seGroupGslb"
//        }
//      ]
//    }
//  }
//}


variable "no_access_vcenter" {
  default = {
    name = "cloudNoAccess"
    environment = "vsphere"
    dhcp_enabled = false
    application = true # if true, it will create an Avi DNS profile with no_access_vcenter.domains as domains and an Avi IPAM profile
    nsxt_exclusion_list = true
    nsxt_se_dfw = true
    se_prefix = "EasyAvi-"
    nsxt = {
//      server = "10.8.0.20"
      transport_zone = {
        name = "N2_TZ_nested_nsx-overlay"
      }
      tier1s = [
        {
          name = "N2-T1_AVI_3"
          description = "N2-T1_AVI_3"
          route_advertisement_types = [
            "TIER1_STATIC_ROUTES",
            "TIER1_CONNECTED",
            "TIER1_LB_VIP"]
          # TIER1_LB_VIP needs to be tested - 20.1.3 TOI
          tier0 = "N2_T0"
        }
      ]
//      network_management = {
//        name = "N2-T1_Segment-Mgmt-10.15.3.0-24"
//        tier1 = "N2-T1_AVI"
//        defaultGateway = "10.15.3.1/24"
//      }
//      network_vip = {
//        name = "N2-T1_Segment-VIP-A_10.15.4.0-24"
//        tier1 = "N2-T1_AVI"
//        defaultGateway = "10.15.4.1/24"
//      }
      networks_data = [
        {
          name = "N2-T1_Segment-VIP-A_10.15.7.0-24"
          tier1 = "N2-T1_AVI_3"
          defaultGateway = "10.15.7.1/24"
        },
        {
          name = "N2-T1_Segment-VIP-B_10.15.8.0-24"
          tier1 = "N2-T1_AVI_3"
          defaultGateway = "10.15.8.1/24"
        }
      ]
    }
    vcenter = {
      dc = "N2-DC"
      cluster = "N2-Cluster1"
      datastore = "vsanDatastore"
      resource_pool = "N2-Cluster1/Resources"
      folderAvi = "Avi-Controllers"
    }
    domains = [
      {
        name = "tkg.altherr.info"
      }
    ]
    network_management = {
      name = "N2-T1_Segment-Mgmt-10.15.3.0-24" # for jump and Avi Controller
      defaultGateway = "10.15.3.1/24"
    }
    network_vip = {
      name = "N2-T1_Segment-VIP-A_10.15.7.0-24" # this is used for Avi IPAM profile config.
      defaultGateway = "10.15.7.1/24"
//      defaultGatewaySe = true
      type = "V4"
      ipStartPool = "50"
      ipEndPool = "60"
      exclude_discovered_subnets = "true"
      vcenter_dvs = "true"
      dhcp_enabled = "false"
    }
    serviceEngineGroup = [
      {
        name = "Default-Group"
        numberOfSe = 0
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = "1"
        disk_per_se = "25"
        vcpus_per_se = "1"
        cpu_reserve = "false"
        memory_per_se = "1024"
        mem_reserve = "false"
        extra_shared_config_memory = "0"
        management_network = {
          name = "N2-T1_Segment-Mgmt-10.15.3.0-24"
          defaultGateway = "10.15.3.1/24"
          ips = [
            "21",
            "22"
          ]
          dhcp = false
        }
        data_networks = [
          {
            name = "N2-T1_Segment-VIP-A_10.15.7.0-24"
            defaultGateway = "10.15.7.1/24"
            defaultGatewaySeGroup = false
            ips = [
              "21",
              "22"
            ]
            dhcp = false
          },
          {
            name = "N2-T1_Segment-VIP-B_10.15.8.0-24"
            defaultGateway = "10.15.8.1/24"
            defaultGatewaySeGroup = false
            ips = [
              "21",
              "22"
            ]
            dhcp = false
          }
        ]
      },
      {
        name = "n2-tkg-cluster-01"
        numberOfSe = 2
//        dhcp = false # only for management
        ha_mode = "HA_MODE_SHARED_PAIR"
        min_scaleout_per_vs = "2"
        disk_per_se = "25"
        vcpus_per_se = "1"
        cpu_reserve = "false"
        memory_per_se = "1024"
        mem_reserve = "false"
        extra_shared_config_memory = "0"
        management_network = {
          name = "N2-T1_Segment-Mgmt-10.15.3.0-24"
          defaultGateway = "10.15.3.1/24"
          ips = [
            "23",
            "24"
          ]
          dhcp = false
        }
        data_networks = [
          {
            name = "N2-T1_Segment-VIP-A_10.15.7.0-24"
            defaultGateway = "10.15.7.1/24"
            defaultGatewaySeGroup = true
            ips = [
              "23",
              "24"
            ]
            dhcp = false
          },
          {
            name = "N2-T1_Segment-VIP-B_10.15.8.0-24"
            defaultGateway = "10.15.8.1/24"
            defaultGatewaySeGroup = false
            ips = [
              "23",
              "24"
            ]
            dhcp = false
          }
        ]
      }
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

