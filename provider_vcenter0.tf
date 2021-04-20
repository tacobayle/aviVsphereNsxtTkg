
provider "vsphere" {
  user                 = "admin"
  password             = "password1"
  vsphere_server       = "10.8.0.10"
  alias                = "vcenter0"
  allow_unverified_ssl = true
}

