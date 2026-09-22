terraform {
  required_version = ">= 1.6"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" {
  region = var.aws_region
  default_tags { tags = local.tags }
}
variable "aws_region" { type = string }
variable "name_prefix" { type = string }
variable "alarm_email" {
  type    = string
  default = ""
}
locals {
  name = "${var.name_prefix}-02"
  tags = { Project = var.name_prefix, Lab = "02", ManagedBy = "Terraform" }
}
module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = "10.2.0.0/16"
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
    dnf install -y amazon-cloudwatch-agent nginx
    systemctl enable --now nginx
  EOF
}
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws-ops-lab/02/application"
  retention_in_days = 3
}
resource "aws_sns_topic" "alarm" { name = "${local.name}-alarm" }
resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
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
  alarm_actions       = [aws_sns_topic.alarm.arn]
  ok_actions          = [aws_sns_topic.alarm.arn]
}
output "instance_id" { value = module.server.instance_id }
output "alarm_name" { value = aws_cloudwatch_metric_alarm.cpu.alarm_name }
output "log_group" { value = aws_cloudwatch_log_group.app.name }
