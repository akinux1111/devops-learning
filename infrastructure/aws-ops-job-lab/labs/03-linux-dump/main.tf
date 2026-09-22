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
locals {
  name = "${var.name_prefix}-03"
  tags = { Project = var.name_prefix, Lab = "03", ManagedBy = "Terraform" }
}
module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = "10.3.0.0/16"
}
module "server" {
  source             = "../../modules/ec2_ssm"
  name               = "${local.name}-server"
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.network.security_group_id]
  user_data          = <<-EOF
    #!/bin/bash
    dnf install -y gcc gdb java-17-amazon-corretto-devel
    mkdir -p /opt/dump-lab && cd /opt/dump-lab
    printf '#include <stdlib.h>\nint main(){abort();}\n' > crash.c
    gcc -g -o crash crash.c
    cat > ThreadLab.java <<'JAVA'
    public class ThreadLab { public static void main(String[] a) throws Exception { while(true){ Thread.sleep(1000); } } }
    JAVA
    javac ThreadLab.java
    nohup java ThreadLab >/var/log/thread-lab.log 2>&1 &
    echo '/opt/dump-lab/core.%e.%p' > /proc/sys/kernel/core_pattern
  EOF
}
output "instance_id" { value = module.server.instance_id }
output "ssm_command" { value = "aws ssm start-session --target ${module.server.instance_id}" }
