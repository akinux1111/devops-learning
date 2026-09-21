variable "aws_region" {
  description = "AWS Region for the disposable Linux lab."
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix used for lab resource names and tags."
  type        = string
  default     = "devops-linux-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.name_prefix))
    error_message = "name_prefix must be 3-24 lowercase letters, digits, or hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.90.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for both lab nodes."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size_gib" {
  description = "Encrypted gp3 root volume size for each node."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size_gib >= 8 && var.root_volume_size_gib <= 32
    error_message = "root_volume_size_gib must be between 8 and 32 GiB for this lab."
  }
}

variable "owner" {
  description = "Non-sensitive owner tag used for cost tracking."
  type        = string
  default     = "akinux1111"
}
