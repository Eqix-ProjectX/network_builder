output "hostname_instance" {
  value = module.instance.hostname
}
output "instance_id" {
  value = module.instance.id
}
output "instance_pip" {
  value = module.instance.pip
}
output "hostname_vd" {
  value = module.ne.hostname_vd
  sensitive = true
}
output "hostname_vd_sec" {
  value = module.ne.hostname_vd_sec
  sensitive = true
}
output "ssh_ip_vd" {
  value = module.ne.ssh_ip_vd
}
output "ssh_ip_vd_sec" {
  value = module.ne.ssh_ip_vd_sec
}