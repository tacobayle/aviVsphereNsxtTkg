data "template_file" "jump0" {
vars = {
  pubkey        = file(var.jump.public_key_path)
  aviSdkVersion = var.jump.aviSdkVersion
  ansibleVersion = var.ansible.version
  username = var.jump.username
  ip = cidrhost(var.nsxt.network_management.defaultGateway, var.nsxt.network_management.jump_ip)
  mask = split("/", var.nsxt.network_management.defaultGateway)[1]
  defaultGw = split("/", var.nsxt.network_management.defaultGateway)[0]
  netplanFile = var.jump.netplanFile
  dns = var.nsxt.network_management.dns
  }
}

resource "vsphere_virtual_machine" "jump" {
  provider          = vsphere.vcenter0
  name              = "jump"
  datastore_id      = data.vsphere_datastore.datastore0.id
  resource_pool_id  = data.vsphere_resource_pool.pool0.id
  folder            = data.vsphere_folder.folderController.path
  network_interface {
    network_id = data.vsphere_network.networkMgmt0.id
  }
  num_cpus = var.jump.cpu
  memory = var.jump.memory
  wait_for_guest_net_routable = var.jump.wait_for_guest_net_routable
  guest_id = "guestid-jump"
  disk {
    size             = var.jump.disk
    label            = "jump.lab_vmdk"
    thin_provisioned = true
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = vsphere_content_library_item.ubuntuJump0.id
  }
  vapp {
    properties = {
      hostname    = "jump"
      public-keys = file(var.jump.public_key_path)
      user-data   = base64encode(data.template_file.jump0.rendered)
    }
  }
}
