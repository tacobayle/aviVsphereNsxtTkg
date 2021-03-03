resource "vsphere_tag" "ansible_group_jump" {
  name             = "jump"
  category_id      = vsphere_tag_category.ansible_group_jump.id
}

data "template_file" "jumpbox_userdata" {
  template = file("${path.module}/userdata/jump.userdata")
  vars = {
    pubkey        = file(var.jump.public_key_path)
    aviSdkVersion = var.jump.avisdkVersion
    ansibleVersion = var.ansible.version
    ipCidr  = var.jump.ipCidr
    ip = split("/", var.jump.ipCidr)[0]
    defaultGw = var.jump.defaultGw
    dnsMain      = var.jump.dnsMain
    netplanFile = var.jump.netplanFile
    vsphere_user  = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.no_access_vcenter.vcenter.server
    username = var.jump.username
    privateKey = var.jump.private_key_path
  }
}

resource "vsphere_virtual_machine" "jump" {
  name = var.jump.name
  datastore_id = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder = vsphere_folder.folderController.path
  network_interface {
    network_id = data.vsphere_network.networkMgmt.id
  }

  num_cpus = var.jump.cpu
  memory = var.jump.memory
  wait_for_guest_net_timeout = 10
  wait_for_guest_net_routable = var.jump.wait_for_guest_net_routable
  guest_id = "guestid-jump"

  disk {
    size = var.jump.disk
    label = "jump.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.ubuntu.id
  }

  tags = [
    vsphere_tag.ansible_group_jump.id,
  ]

  vapp {
    properties = {
      hostname = var.jump.username
      public-keys = file(var.jump.public_key_path)
      user-data = base64encode(data.template_file.jumpbox_userdata.rendered)
    }
  }
}