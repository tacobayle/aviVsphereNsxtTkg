//resource "vsphere_content_library" "library" {
//  name            = var.contentLibrary.name
//  storage_backing = [data.vsphere_datastore.datastore.id]
//  description     = var.contentLibrary.description
//}
//
//resource "vsphere_content_library_item" "avi" {
//  name        = basename(var.contentLibrary.avi)
//  description = basename(var.contentLibrary.avi)
//  library_id  = vsphere_content_library.library.id
//  file_url = var.contentLibrary.avi
//}
//
//resource "vsphere_content_library_item" "ubuntu" {
//  name        = basename(var.contentLibrary.ubuntu)
//  description = basename(var.contentLibrary.ubuntu)
//  library_id  = vsphere_content_library.library.id
//  file_url = var.contentLibrary.ubuntu
//}

data "vsphere_content_library" library {
  name            = var.contentLibrary.name
}

data "vsphere_content_library_item" "avi" {
  name       = "controller-20.1.4-9087"
  library_id = data.vsphere_content_library.library.id
}

data "vsphere_content_library_item" "ubuntu" {
  name       = "bionic-server-cloudimg-amd64"
  library_id = data.vsphere_content_library.library.id
  type = "ova"
}