output "pip_id" {
  value = azurerm_public_ip.pip.id
}

output "elb_id" {
  value = azurerm_lb.elb.id 
}

output "ilb_id" {
  value = azurerm_lb.ilb.id 
}

output "vmss_id" {
    value = azurerm_linux_virtual_machine_scale_set.linux_nvavss.id
}
