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
      "git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag}",
    ]
  }

  provisioner "file" {
    source = "hosts"
    destination = "${basename(var.ansible.aviConfigureUrl)}/hosts"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod 600 ~/.ssh/${basename(var.jump.private_key_path)}",
      "cd ${basename(var.ansible.aviConfigureUrl)} ; ansible-playbook -i hosts local.yml --extra-vars '{\"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_version\": ${split("-", basename(var.nsxt.aviOva))[1]}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.nsxt.controller)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"nsx_server\": ${jsonencode(var.nsx_server)}, \"nsx_username\": ${jsonencode(var.nsx_username)}, \"vcenter_credentials\": ${var.vcenter_credentials}, \"nsx_password\": ${jsonencode(var.nsx_password)}, \"vsphere_password\": ${jsonencode(var.vsphere_password)}, \"vsphere_username\": ${jsonencode(var.vsphere_username)}, \"vsphere_server\": ${jsonencode(var.vsphere_server)}, \"nsxt\": ${jsonencode(var.nsxt)}}'",
    ]
  }
}

resource "null_resource" "ansible_no_access_nsxt_dfw_rule" {
  depends_on = [vsphere_virtual_machine.jump]
  count = (var.no_access_vcenter.nsxt_se_dfw == true ? 1 : 0)
  connection {
    host        = vsphere_virtual_machine.jump.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline      = [
      "git clone ${var.ansible.NsxtModuleUrl}",
      "git clone ${var.ansible.nsxtConfigureDfwUrl} --branch ${var.ansible.nsxtConfigureDfwTag}",
      "cp ${basename(var.ansible.nsxtConfigureDfwUrl)}/local.yml ${basename(var.ansible.NsxtModuleUrl)}/local.yml",
      "echo ${basename(var.ansible.NsxtModuleUrl)} ; ls ${basename(var.ansible.NsxtModuleUrl)}",
      "cd ${basename(var.ansible.NsxtModuleUrl)} ; ansible-playbook local.yml -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars '{\"nsx_server\": ${jsonencode(var.nsx_server)}, \"nsx_username\": ${jsonencode(var.nsx_username)}, \"nsx_password\": ${jsonencode(var.nsx_password)}, \"policy_name\": \"no_access_se\", \"policy_scope\": ${jsonencode(nsxt_policy_group.se_no_access[0].path)}, \"rule_name\": \"rule1\", \"source_group\": ${jsonencode(nsxt_policy_group.se_no_access[0].path)}, \"destination_group\": ${jsonencode(nsxt_policy_group.se_no_access[0].path)}, \"rule_scope\": ${jsonencode(nsxt_policy_group.se_no_access[0].path)}}'",
    ]
  }
}

resource "null_resource" "ansible_nsxt_dfw_rule" {
  count = (var.nsxt.nsxt_se_dfw == true ? 1 : 0)
  depends_on = [null_resource.ansible]
  connection {
    host        = vsphere_virtual_machine.jump.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "remote-exec" {
    inline      = [
      "cd ${basename(var.ansible.NsxtModuleUrl)} ; ansible-playbook local.yml -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars '{\"nsx_server\": ${jsonencode(var.nsx_server)}, \"nsx_username\": ${jsonencode(var.nsx_username)}, \"nsx_password\": ${jsonencode(var.nsx_password)}, \"policy_name\": \"nsxt_se\", \"policy_scope\": ${jsonencode(data.nsxt_policy_group.se_nsxt)}, \"rule_name\": \"rule1\", \"source_group\": ${jsonencode(data.nsxt_policy_group.se_nsxt)}, \"destination_group\": ${jsonencode(data.nsxt_policy_group.se_nsxt)}, \"rule_scope\": ${jsonencode(data.nsxt_policy_group.se_nsxt)}}'",
    ]
  }
}


resource "local_file" "destroy" {
  content     = templatefile("${path.module}/template/destroy.sh.tmpl", { privateKey = var.jump.private_key_path, jump_ip = vsphere_virtual_machine.jump.default_ip_address, aviPbAbsentUrl = var.ansible.aviPbAbsentUrl, aviPbAbsentTag = var.ansible.aviPbAbsentTag, aviCredsJsonFile = var.nsxt.controller.aviCredsJsonFile, NsxtModuleUrl = var.ansible.NsxtModuleUrl, nsx_server = jsonencode(var.nsx_server), nsx_username = jsonencode(var.nsx_username), nsx_password = jsonencode(var.nsx_password), policy_name_nsxt = jsonencode(var.nsxt.nsxt_se_dfw_policy_name), policy_name_no_access_vcenter = jsonencode(var.no_access_vcenter.nsxt_se_dfw_policy_name)})
  filename = "${path.module}/destroy.sh"
}