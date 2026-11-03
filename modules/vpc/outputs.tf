output "vpc_id" { value = aws_vpc.this.id }
output "private_subnet_ids" { value = { for az, subnet in aws_subnet.private : az => subnet.id } }
output "public_subnet_ids" { value = { for az, subnet in aws_subnet.public : az => subnet.id } }
output "private_subnet_cidrs" { value = local.private_cidrs }
output "public_subnet_cidrs" { value = local.public_cidrs }
