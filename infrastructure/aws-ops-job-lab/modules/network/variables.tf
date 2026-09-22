variable "name" { type = string }
variable "cidr" { type = string }
variable "az_index" {
  type    = number
  default = 0
}
