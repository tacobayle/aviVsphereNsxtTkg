provider "vsphere" {
  user                 = "hello"
  password             = "world"
  vsphere_server       = "1.1.1.1"
  alias                = "alias"
  allow_unverified_ssl = true
}