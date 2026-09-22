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
variable "hosted_zone_name" {
  type    = string
  default = ""
}
locals {
  name = "${var.name_prefix}-01"
  tags = { Project = var.name_prefix, Lab = "01", ManagedBy = "Terraform" }
}
resource "random_id" "suffix" { byte_length = 4 }
module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = "10.1.0.0/16"
}
module "server" {
  source             = "../../modules/ec2_ssm"
  name               = "${local.name}-web"
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.network.security_group_id]
  user_data          = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo 'AWS Ops Lab 01' > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF
}
resource "aws_s3_bucket" "logs" {
  bucket        = "${local.name}-${random_id.suffix.hex}"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_lb" "alb" {
  name               = substr("${local.name}-alb", 0, 32)
  load_balancer_type = "application"
  subnets            = module.network.subnet_ids
  security_groups    = [module.network.security_group_id]
}
resource "aws_lb_target_group" "web" {
  name     = substr("${local.name}-tg", 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
  health_check { path = "/" }
}
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = module.server.instance_id
  port             = 80
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
resource "aws_lb" "nlb" {
  name               = substr("${local.name}-nlb", 0, 32)
  load_balancer_type = "network"
  subnets            = [module.network.subnet_id]
}
resource "aws_lb_target_group" "tcp" {
  name     = substr("${local.name}-tcp", 0, 32)
  port     = 80
  protocol = "TCP"
  vpc_id   = module.network.vpc_id
}
resource "aws_lb_target_group_attachment" "tcp" {
  target_group_arn = aws_lb_target_group.tcp.arn
  target_id        = module.server.instance_id
  port             = 80
}
resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp.arn
  }
}
data "aws_route53_zone" "selected" {
  count        = var.hosted_zone_name == "" ? 0 : 1
  name         = var.hosted_zone_name
  private_zone = false
}
resource "aws_route53_record" "lab" {
  count   = var.hosted_zone_name == "" ? 0 : 1
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "ops-lab.${var.hosted_zone_name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}
output "instance_id" { value = module.server.instance_id }
output "alb_url" { value = "http://${aws_lb.alb.dns_name}" }
output "nlb_dns" { value = aws_lb.nlb.dns_name }
output "log_bucket" { value = aws_s3_bucket.logs.id }
