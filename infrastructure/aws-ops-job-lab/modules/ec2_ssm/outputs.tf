output "instance_id" { value = aws_instance.this.id }
output "public_ip" { value = aws_instance.this.public_ip }
output "role_arn" { value = aws_iam_role.this.arn }
