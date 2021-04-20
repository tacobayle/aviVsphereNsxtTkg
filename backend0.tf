data "template_file" "backend0" {
  count = 3
  template = file("userdata/backend.userdata")
  vars = {
    defaultGw          = split("/", var.nsxt.network_backend.defaultGateway)[0]
    pubkey             = file(var.jump.public_key_path)
    ip                 = cidrhost(var.nsxt.network_backend.defaultGateway, count.index + 0)
    subnetMask         = split("/", var.nsxt.network_backend.defaultGateway)[1]
    netplanFile        = var.backend.netplanFile
    dnsMain            = var.backend.dnsMain
    dnsSec             = var.backend.dnsSec
    url_demovip_server = var.backend.url_demovip_server
    username           = var.backend.username
  }
}
resource "vsphere_virtual_machine" "backend0" {
  provider          = vsphere.vcenter0
  count             = 3
  name              = "backend-${count.index}"
  datastore_id      = data.vsphere_datastore.datastore0.id
  resource_pool_id  = data.vsphere_resource_pool.pool0.id
  folder            = vsphere_folder.folderApp0.path
  network_interface {
    network_id = data.vsphere_network.networkBackend0.id
  }
  num_cpus = var.backend.cpu
  memory = var.backend.memory
  wait_for_guest_net_routable = var.backend.wait_for_guest_net_routable
  guest_id = "guestid-backend-${count.index}"
  disk {
    size             = var.backend.disk
    label            = "backend-${count.index}.lab_vmdk"
    thin_provisioned = true
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = vsphere_content_library_item.ubuntu0.id
  }
  vapp {
    properties = {
      hostname    = "backend-${count.index}"
      public-keys = file(var.jump.public_key_path)
      user-data   = base64encode(data.template_file.backend0[count.index].rendered)
    }
  }
  connection {
    host        = cidrhost("var.nsxt.network_backend.defaultGateway", count.index + 0)
    type        = "ssh"
    agent       = false
    user        = var.backend.username
    private_key = file(var.jump.private_key_path)
    }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}
