resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { "Name" = var.vpc_name })
}

# Create the Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { "Name" = "${var.vpc_name}-IGW" })
}

# Create public subnets for each provided CIDR block
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    "Name" = "${var.environment}-Public-${count.index + 1}"
  })
}

# Create private subnets for each provided CIDR block
resource "aws_subnet" "private" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnet_cidrs[count.index]
  # Cycle through the availability zones if there are more subnets than AZs
  availability_zone       = element(var.azs, count.index % length(var.azs))
  map_public_ip_on_launch = false
  tags = merge(var.tags, {
    "Name" = "${var.environment}-Private-${count.index + 1}"
  })
}

# Allocate an Elastic IP for the NAT Gateway (must be in the VPC)
resource "aws_eip" "nat" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]
}

# Create a NAT Gateway in the first public subnet so that private subnets can access the Internet
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.tags, { "Name" = "${var.environment}-NATGW" })
  depends_on    = [aws_internet_gateway.this]
}

# Create a public route table with a default route via the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { "Name" = "${var.environment}-Public-RT" })
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a private route table with a default route through the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = merge(var.tags, { "Name" = "${var.environment}-Private-RT" })
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
