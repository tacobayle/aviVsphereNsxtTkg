resource "vsphere_virtual_machine" "controller" {
  provider        = vsphere.vcenter0
  count            = (var.nsxt.controller.cluster == true ? 3 : 1)
  name             = "${split(".ova", basename(var.nsxt.aviOva))[0]}-${count.index}"
  datastore_id      = data.vsphere_datastore.datastore0.id
  resource_pool_id  = data.vsphere_resource_pool.pool0.id
  folder           = data.vsphere_folder.folderController.path

  network_interface {
    network_id = data.vsphere_network.networkMgmt0.id
  }

  num_cpus = var.nsxt.controller.cpu
  memory = var.nsxt.controller.memory
  wait_for_guest_net_timeout = var.nsxt.controller.wait_for_guest_net_timeout
  guest_id = "guestid-${split(".ova", basename(var.nsxt.aviOva))[0]}-${count.index}"

  disk {
    size             = var.nsxt.controller.disk
    label            = "controller-${split(".ova", basename(var.nsxt.aviOva))[0]}-${count.index}.lab_vmdk"
    thin_provisioned = true
  }
  clone {
    template_uuid = vsphere_content_library_item.avi0.id
  }
  vapp {
    properties = {
      "mgmt-ip"     = cidrhost(var.nsxt.network_management.defaultGateway, element(var.nsxt.network_management.avi_ctrl_mgmt_ips, count.index))
      "mgmt-mask"   = cidrnetmask(var.nsxt.network_management.defaultGateway)
      "default-gw"  = split("/", var.nsxt.network_management.defaultGateway)[0]
    }
  }
}
