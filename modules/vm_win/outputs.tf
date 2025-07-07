output "vm_id" {
  value = azurerm_windows_virtual_machine.uks_win_vm.id
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.uks_win_vm.name
}

output "public_ip" {
  value = var.public_ip_enabled ? azurerm_public_ip.uks_win_vm_pip[0].ip_address : null
}
