resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "psk" {
  length           = 16
  special          = true
  override_special = "_%@"
}

output "vm_password" {
  value     = random_password.password.result
  sensitive = true
}