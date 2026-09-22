variable "name" { type = string }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "user_data" {
  type    = string
  default = ""
}
variable "extra_policy_arns" {
  type    = list(string)
  default = []
}
variable "root_volume_size" {
  type    = number
  default = 8
}
variable "detailed_monitoring" {
  type    = bool
  default = false
}
