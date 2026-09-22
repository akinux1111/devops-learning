output "vpc_id" { value = aws_vpc.this.id }
output "subnet_id" { value = aws_subnet.public.id }
output "subnet_ids" { value = [aws_subnet.public.id, aws_subnet.public_secondary.id] }
output "security_group_id" { value = aws_security_group.web.id }
output "availability_zone" { value = aws_subnet.public.availability_zone }
