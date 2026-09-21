variable "aws_region" {
  description = "AWS Region for the manual SSM foundation lab."
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix used for foundation resource names and tags."
  type        = string
  default     = "devops-ssm-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.name_prefix))
    error_message = "name_prefix must be 3-24 lowercase letters, digits, or hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the manual SSM lab VPC."
  type        = string
  default     = "10.91.0.0/16"
}

variable "owner" {
  description = "Non-sensitive owner tag used for cost tracking."
  type        = string
  default     = "akinux1111"
}
