resource "null_resource" "ansible_hosts_static1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts ; echo 'all:' | tee -a hosts ; echo '  children:' | tee -a hosts ; echo '    controller:' | tee -a hosts ; echo '      hosts:' | tee -a hosts"
  }
}

resource "null_resource" "ansible_hosts_controllers_dynamic" {
  depends_on = [null_resource.ansible_hosts_static1]
  count      = (var.nsxt.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.controller[count.index].default_ip_address}:' | tee -a hosts"
  }
}

resource "null_resource" "ansible" {
  depends_on = [vsphere_virtual_machine.jump, null_resource.ansible_hosts_controllers_dynamic]
  connection {
    host        = vsphere_virtual_machine.jump.default_ip_address
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
    inline = [
      "sudo mkdir -p /etc/ansible",
      "echo '[defaults]' | sudo tee /etc/ansible/ansible.cfg",
      "echo 'private_key_file = /home/${var.jump.username}/.ssh/${basename(var.jump.private_key_path)}' | sudo tee -a /etc/ansible/ansible.cfg",
      "echo 'host_key_checking = False' | sudo tee -a /etc/ansible/ansible.cfg",
      "echo 'host_key_auto_add = True' | sudo tee -a /etc/ansible/ansible.cfg",
      "git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag}"
    ]
  }

  provisioner "file" {
    source = "hosts"
    destination = "${basename(var.ansible.aviConfigureUrl)}/hosts"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump.private_key_path)}",
      "cd ${basename(var.ansible.aviConfigureUrl)} ; ansible-playbook -i hosts local.yml --extra-vars '{\"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_version\": ${split("-", basename(var.nsxt.aviOva))[1]}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.nsxt.controller)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"nsx_server\": ${jsonencode(var.nsx_server)}, \"nsx_username\": ${jsonencode(var.nsx_username)}, \"vcenter_credentials\": ${jsonencode(var.vcenter_credentials.vcenter_credentials)}, \"nsx_password\": ${jsonencode(var.nsx_password)}, \"nsxt\": ${jsonencode(var.nsxt)}}'",
    ]
  }
}

data "template_file" "destroy" {
  template = file("${path.module}/template/destroy.sh.tmpl")
  vars = {
    privateKey = var.jump.private_key_path
    jump_ip = vsphere_virtual_machine.jump.default_ip_address
    aviPbAbsentUrl = var.ansible.aviPbAbsentUrl
    aviPbAbsentTag = var.ansible.aviPbAbsentTag
    aviCredsJsonFile = var.nsxt.controller.aviCredsJsonFile
  }
}

resource "null_resource" "destroy" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.destroy.rendered}' | tee -a destroy.sh"
  }
}