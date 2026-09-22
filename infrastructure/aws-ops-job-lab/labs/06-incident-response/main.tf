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
  name = "${var.name_prefix}-06"
  tags = { Project = var.name_prefix, Lab = "06", ManagedBy = "Terraform" }
}
resource "random_id" "suffix" { byte_length = 4 }
module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = "10.6.0.0/16"
}
module "server" {
  source              = "../../modules/ec2_ssm"
  name                = "${local.name}-server"
  subnet_id           = module.network.subnet_id
  security_group_ids  = [module.network.security_group_id]
  detailed_monitoring = true
  extra_policy_arns   = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
  user_data           = <<-EOF
    #!/bin/bash
    dnf install -y nginx amazon-cloudwatch-agent
    echo 'healthy' > /usr/share/nginx/html/health
    systemctl enable --now nginx
  EOF
}
resource "aws_cloudwatch_log_group" "incident" {
  name              = "/aws-ops-lab/06/incident"
  retention_in_days = 3
}
resource "aws_sns_topic" "incident" { name = "${local.name}-incident" }
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${local.name}-high-cpu"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 60
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = module.server.instance_id }
  alarm_actions       = [aws_sns_topic.incident.arn]
}
resource "aws_s3_bucket" "evidence" {
  bucket        = "${local.name}-evidence-${random_id.suffix.hex}"
  force_destroy = true
}
output "instance_id" { value = module.server.instance_id }
output "alarm_name" { value = aws_cloudwatch_metric_alarm.cpu.alarm_name }
output "evidence_bucket" { value = aws_s3_bucket.evidence.id }
