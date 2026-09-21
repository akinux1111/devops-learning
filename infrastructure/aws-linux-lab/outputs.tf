output "node_ids" {
  description = "EC2 instance IDs in node order."
  value       = aws_instance.node[*].id
}

output "node_private_ips" {
  description = "Private IP addresses used for node-to-node labs."
  value       = aws_instance.node[*].private_ip
}

output "node_public_ips" {
  description = "Public IPs exist for outbound access; the security group has no inbound rules."
  value       = aws_instance.node[*].public_ip
}

output "ssm_start_commands" {
  description = "Session Manager commands for both nodes."
  value = [
    for instance in aws_instance.node :
    "aws ssm start-session --region ${var.aws_region} --target ${instance.id}"
  ]
}

output "lab_summary" {
  description = "Non-sensitive summary of the disposable lab."
  value = {
    region            = var.aws_region
    vpc_id            = aws_vpc.lab.id
    security_group_id = aws_security_group.nodes.id
    node_count        = local.node_count
    instance_type     = var.instance_type
  }
}
