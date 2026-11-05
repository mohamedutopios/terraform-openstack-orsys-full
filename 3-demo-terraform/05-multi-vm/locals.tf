# Conventions de nommage : demo5-vm-1, demo5-vm-2, ...
locals {
  prefix   = "demo5"
  key_name = "${local.prefix}-key"

  vm_names   = [for i in range(var.vm_count) : "${local.prefix}-vm-${i + 1}"]
  port_names = [for i in range(var.vm_count) : "${local.prefix}-port-${i + 1}"]
}
