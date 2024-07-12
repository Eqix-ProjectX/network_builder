variable "project_id" {}
variable "plan" {
  type    = string
  default = "c3.small.x86"
}
variable "metro" {}
variable "operating_system" {}
variable "billing_cycle" {
  type    = string
  default = "hourly"
}
variable "nums" {
  type = number
}
variable "core_count" {}
variable "metro_code" {}
variable "notifications" {}
variable "package_code" {}
variable "sec_metro_code" {}
variable "type_code" {}
variable "ver" {}
variable "account_number" {}
variable "sec_account_number" {}
variable "username" {}
variable "key_name" {}
variable "acl_template_id" {}
variable "private_key" {}
variable "vrf_desc" {}
variable "vrf_name" {}
variable "vrf_asn" {}
variable "vrf_ranges" {}
variable "vlan_desc" {}
variable "range_desc" {}
variable "cidr" {}
variable "network_range" {}