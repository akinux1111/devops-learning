terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}
provider "aws" {
  region = var.aws_region
  default_tags { tags = local.tags }
}
variable "aws_region" { type = string }
variable "name_prefix" { type = string }
locals {
  name = "${var.name_prefix}-05"
  tags = { Project = var.name_prefix, Lab = "05", ManagedBy = "Terraform" }
}
resource "random_id" "suffix" { byte_length = 4 }
module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = "10.5.0.0/16"
}
module "server" {
  source             = "../../modules/ec2_ssm"
  name               = "${local.name}-server"
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.network.security_group_id]
  root_volume_size   = 12
}
resource "aws_ebs_volume" "data" {
  availability_zone = module.network.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true
  tags              = { Name = "${local.name}-data" }
}
resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = module.server.instance_id
}
resource "aws_s3_bucket" "archive" {
  bucket        = "${local.name}-${random_id.suffix.hex}"
  force_destroy = true
}
resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule {
    id     = "tier-and-expire"
    status = "Enabled"
    filter { prefix = "logs/" }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
    expiration { days = 365 }
  }
}
output "instance_id" { value = module.server.instance_id }
output "ebs_volume_id" { value = aws_ebs_volume.data.id }
output "archive_bucket" { value = aws_s3_bucket.archive.id }
