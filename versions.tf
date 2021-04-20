terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
      version = "= 3.1.1"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = "= 1.24.3"
    }
    template = {
      source = "hashicorp/template"
      version = "= 2.2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "= 3.0.0"
    }
    time = {
      source = "hashicorp/time"
      version = "= 0.6.0"
    }
  }
  required_version = ">= 0.13"
}