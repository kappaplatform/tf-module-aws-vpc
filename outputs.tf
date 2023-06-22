output "vpc" {
  value = {
    vpc_id               = aws_vpc.this.id
    cidr_block           = aws_vpc.this.cidr_block
    ipv6_cidr_block      = aws_vpc.this.ipv6_cidr_block
    igw_id               = aws_internet_gateway.this.id
    egress_only_igw_id   = aws_egress_only_internet_gateway.this.id
    s3_endpoint_id       = aws_vpc_endpoint.s3.id
    dynamodb_endpoint_id = aws_vpc_endpoint.dynamodb.id
  }
}

output "private_subnets" {
  value = {
    for az in local.sorted_azs : az => {
      subnet_id       = aws_subnet.private[az].id
      cidr_block      = aws_subnet.private[az].cidr_block
      ipv6_cidr_block = aws_subnet.private[az].ipv6_cidr_block
      route_table_id  = aws_route_table.private[az].id
    }
  }
}

output "public_subnets" {
  value = {
    for az in local.sorted_azs : az => {
      subnet_id       = aws_subnet.public[az].id
      cidr_block      = aws_subnet.public[az].cidr_block
      ipv6_cidr_block = aws_subnet.public[az].ipv6_cidr_block
      route_table_id  = aws_route_table.public[az].id
    }
  }
}
