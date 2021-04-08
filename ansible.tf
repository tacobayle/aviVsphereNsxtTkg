
resource "null_resource" "foo" {
  depends_on = [vsphere_virtual_machine.jump]
  connection {
    host        = split("/", var.jump["ipCidr"])[0]
    type        = "ssh"
    agent       = false
    user        = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }

  provisioner "file" {
    source      = var.jump.private_key_path
    destination = "~/.ssh/${basename(var.jump.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump.private_key_path)}",
      "git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag} ; cd ${split("/", var.ansible.aviConfigureUrl)[4]} ; ansible-playbook -i /opt/ansible/inventory/inventory.vmware.yml local.yml --extra-vars '{\"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_version\": ${split("-", basename(var.contentLibrary.avi))[1]}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.controller)}, \"vsphere_username\": ${jsonencode(var.vsphere_username)}, \"vsphere_password\": ${jsonencode(var.vsphere_password)}, \"vsphere_server\": ${jsonencode(var.vsphere_server)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"nsx_server\": ${jsonencode(var.nsx_server)}, \"nsx_username\": ${jsonencode(var.nsx_username)}, \"nsxt\": ${jsonencode(var.nsxt)}}'",
    ]
  }
}