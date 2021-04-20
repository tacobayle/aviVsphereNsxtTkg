data "vsphere_datacenter" "dc0" {
  provider = vsphere.vcenter0
  name = "N1-DC"
}

data "vsphere_compute_cluster" "compute_cluster0" {
  provider      = vsphere.vcenter0
  name          = "N1-Cluster1"
  datacenter_id = data.vsphere_datacenter.dc0.id
}

data "vsphere_datastore" "datastore0" {
  provider      = vsphere.vcenter0
  name          = "vsanDatastore1"
  datacenter_id = data.vsphere_datacenter.dc0.id
}

data "vsphere_resource_pool" "pool0" {
  provider      = vsphere.vcenter0
  name          = "N1-Cluster1"/Resources
  datacenter_id = data.vsphere_datacenter.dc0.id
}

resource "vsphere_content_library" "libraryAviSE0" {
  provider        = vsphere.vcenter0
  name            = "EasyAvi-CL-SE"
  storage_backing = [data.vsphere_datastore.datastore0.id]
}

data "vsphere_network" "networkMgmt0" {
  name          = var.nsxt.network_management.name
  datacenter_id = data.vsphere_datacenter.dc0.id
}

data "vsphere_folder" "folderController" {
  path = "N1-DC/vm/Avi-Controllers"
}

resource "vsphere_content_library" "libraryAvi0" {
  provider        = vsphere.vcenter0
  name            = "EasyAvi-CL-Avi"
  storage_backing = [data.vsphere_datastore.datastore0.id]
}

resource "vsphere_content_library_item" "avi0" {
  provider        = vsphere.vcenter0
  name            = "controller-20.1.4-9087.ova"
  library_id      = vsphere_content_library.libraryAvi0.id
  file_url        = "/home/christoph/Downloads/controller-20.1.4-9087.ova"
}

resource "vsphere_content_library_item" "ubuntuJump0" {
  provider        = vsphere.vcenter0
  name            = "bionic-server-cloudimg-amd64.ova"
  library_id      = vsphere_content_library.libraryAvi0.id
  file_url        = "/home/christoph/Downloads/bionic-server-cloudimg-amd64.ova"
}

resource "vsphere_content_library" "App0" {
  provider        = vsphere.vcenter0
  name            = "EasyAvi-CL-App"
  storage_backing = [data.vsphere_datastore.datastore0.id]
}

resource "vsphere_content_library_item" "ubuntu0" {
  provider        = vsphere.vcenter0
  name            = "ubuntu"
  library_id      = vsphere_content_library.App0.id
  file_url        = "/home/christoph/Downloads/bionic-server-cloudimg-amd64.ova"
}

data "vsphere_network" "networkBackend0" {
  name          = var.nsxt.network_backend.name
  datacenter_id = data.vsphere_datacenter.dc0.id
}

