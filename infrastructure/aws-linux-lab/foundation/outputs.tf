output "vpc_id" {
  description = "VPC ID to select while creating the security group manually."
  value       = aws_vpc.lab.id
}

output "public_subnet_id" {
  description = "Subnet ID to select while launching the manual EC2 instance."
  value       = aws_subnet.public.id
}

output "availability_zone" {
  description = "Availability Zone of the public subnet."
  value       = aws_subnet.public.availability_zone
}

output "route_table_id" {
  description = "Route table ID to inspect during the network exercise."
  value       = aws_route_table.public.id
}
