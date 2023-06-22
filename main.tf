terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
  }
}

data "aws_region" "current" {
}

data "aws_availability_zone" "this" {
  for_each = var.availability_zones

  name = "${data.aws_region.current.name}${each.value}"
}

### VPC

resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true

  tags = var.resource_tags
}

### Subnets

locals {
  sorted_azs = sort(var.availability_zones)

  all_subnet_ipv4_cidrs     = cidrsubnets(var.vpc_cidr, 2, 2, 2, 4, 4, 4)
  private_subnet_ipv4_cidrs = zipmap(local.sorted_azs, slice(local.all_subnet_ipv4_cidrs, 0, 3))
  public_subnet_ipv4_cidrs  = zipmap(local.sorted_azs, slice(local.all_subnet_ipv4_cidrs, 3, 6))

  all_subnet_ipv6_cidrs     = cidrsubnets(aws_vpc.this.ipv6_cidr_block, 8, 8, 8, 8, 8, 8)
  private_subnet_ipv6_cidrs = zipmap(local.sorted_azs, slice(local.all_subnet_ipv6_cidrs, 0, 3))
  public_subnet_ipv6_cidrs  = zipmap(local.sorted_azs, slice(local.all_subnet_ipv6_cidrs, 3, 6))
}

resource "aws_subnet" "private" {
  for_each = local.sorted_azs

  vpc_id                              = aws_vpc.this.id
  availability_zone                   = "${data.aws_region.current.name}${each.key}"
  cidr_block                          = local.private_subnet_ipv4_cidrs[each.value]
  ipv6_cidr_block                     = local.private_subnet_ipv6_cidrs[each.value]
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "resource-name"

  tags = var.resource_tags
}

resource "aws_subnet" "public" {
  for_each = local.sorted_azs

  vpc_id                              = aws_vpc.this.id
  availability_zone                   = "${data.aws_region.current.name}${each.value}"
  cidr_block                          = local.public_subnet_ipv4_cidrs[each.value]
  ipv6_cidr_block                     = local.public_subnet_ipv6_cidrs[each.value]
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "resource-name"

  tags = var.resource_tags
}

### Private route tables

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = var.resource_tags
}

resource "aws_route_table" "private" {
  for_each = local.sorted_azs

  vpc_id = aws_vpc.this.id

  tags = var.resource_tags
}

resource "aws_route" "private_default_ipv6" {
  for_each = local.sorted_azs

  route_table_id              = aws_route_table.private[each.value].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this.id
}

resource "aws_route_table_association" "private" {
  for_each = local.sorted_azs

  route_table_id = aws_route_table.private[each.value].id
  subnet_id      = aws_subnet.private[each.value].id
}

### Public route tables

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = var.resource_tags
}

resource "aws_route_table" "public" {
  for_each = local.sorted_azs

  vpc_id = aws_vpc.this.id

  tags = var.resource_tags
}

resource "aws_route" "public_default_ipv4" {
  for_each = local.sorted_azs

  route_table_id              = aws_route_table.public[each.value].id
  destination_ipv6_cidr_block = "0.0.0.0/0"
  gateway_id                  = aws_internet_gateway.this.id
}

resource "aws_route" "public_default_ipv6" {
  for_each = local.sorted_azs

  route_table_id              = aws_route_table.public[each.value].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = local.sorted_azs

  route_table_id = aws_route_table.public[each.value].id
  subnet_id      = aws_subnet.public[each.value].id
}

### S3 gateway endpoint

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current}.s3"

  tags = var.resource_tags
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  for_each = local.sorted_azs

  route_table_id  = aws_route_table.private[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  for_each = local.sorted_azs

  route_table_id  = aws_route_table.public[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

### DynamoDB gateway endpoint

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current}.dynamodb"

  tags = var.resource_tags
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
  for_each = local.sorted_azs

  route_table_id  = aws_route_table.private[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
  for_each = local.sorted_azs

  route_table_id  = aws_route_table.public[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
}
