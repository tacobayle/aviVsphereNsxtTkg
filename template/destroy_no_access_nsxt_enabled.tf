resource "local_file" "destroy_no_access_nsxt" {
  content     = templatefile("${path.module}/template/destroy_no_access_nsxt_enabled.tmpl", { privateKey = var.jump.private_key_path, jump_ip = vsphere_virtual_machine.jump.default_ip_address, NsxtModuleUrl = var.ansible.NsxtModuleUrl, nsx_server = jsonencode(var.nsx_server), nsx_username = jsonencode(var.nsx_username), nsx_password = jsonencode(var.nsx_password), policy_name_nsxt = jsonencode(var.no_access_vcenter.nsxt_se_dfw_policy_name)})
  filename = "${path.module}/destroy_no_access_nsxt.sh"
}