locals {
  alb_ports_in = [443, 80]
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  count                   = length(var.public_subnet_cidr)
  cidr_block              = element(var.public_subnet_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-subnet-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet)
}

