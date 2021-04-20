#
provider "nsxt" {
  host                     = var.nsx_server
  username                 = var.nsx_username
  password                 = var.nsx_password
  allow_unverified_ssl     = true
  max_retries              = 10
  retry_min_delay          = 500
  retry_max_delay          = 5000
  retry_on_status_codes    = [429]
}
//#
//provider "vsphere" {
//  user           = var.vsphere_username
//  password       = var.vsphere_password
//  vsphere_server = var.vsphere_server
//  alias = "main"
//
//  # If you have a self-signed cert
//  allow_unverified_ssl = true
//}
