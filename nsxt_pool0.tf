resource "nsxt_policy_group" "backend0" {
  display_name = "EasyAvi - Backend - vCenter0"
  criteria {
    condition {
      key = "Tag"
      member_type = "VirtualMachine"
      operator = "EQUALS"
      value = "EasyAvi - Backend - vCenter0"
    }
  }
}

resource "nsxt_vm_tags" "backend0" {
  count = var.nsxt.backend_per_vcenter - 1
  instance_id = vsphere_virtual_machine.backend0[count.index].id
  tag {
    tag   = "EasyAvi - Backend - vCenter0"
  }
}
