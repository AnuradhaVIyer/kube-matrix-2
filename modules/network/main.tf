data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  name_prefix = "${var.project}-${var.component}-${var.environment}-${replace(var.region, "-", "")}"
  base_tags = merge(var.tags, {
    Name        = local.name_prefix
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = var.component
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.base_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.base_tags, { Name = "${local.name_prefix}-igw" })
}

# PUBLIC SUBNETS (one per AZ)
resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : idx => az }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs[each.key] : cidrsubnet(var.vpc_cidr, 8, each.key)
  map_public_ip_on_launch = true
  tags = merge(local.base_tags, {
    Name                            = "${local.name_prefix}-subnet-public-${each.value}"
    "kubernetes.io/role/elb"        = "1"
  })
}

# PRIVATE SUBNETS (one per AZ)
resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : idx => az }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs[each.key] : cidrsubnet(var.vpc_cidr, 8 + 1, each.key)
  map_public_ip_on_launch = false
  tags = merge(local.base_tags, {
    Name = "${local.name_prefix}-subnet-private-${each.value}"
    "kubernetes.io/cluster/${var.project}" = "owned"
  })
}

# Public route table and default route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.base_tags, { Name = "${local.name_prefix}-rtb-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# EIP and NAT Gateway(s)
resource "aws_eip" "nat" {
  count = var.enable_nat_per_az ? length(aws_subnet.public) : 1
  depends_on = [aws_internet_gateway.igw]
  tags = merge(local.base_tags, { Name = "${local.name_prefix}-eip-nat-${count.index}" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_per_az ? length(aws_subnet.public) : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, count.index)
  tags = merge(local.base_tags, { Name = "${local.name_prefix}-nat-${count.index}" })
  depends_on = [aws_internet_gateway.igw]
}

# Private route tables per private subnet -> NAT
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id = aws_vpc.this.id
  tags   = merge(local.base_tags, { Name = "${local.name_prefix}-rtb-private-${each.key}" })
}

resource "aws_route" "private_default" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = var.enable_nat_per_az ? aws_nat_gateway.nat[tonumber(each.key)].id : aws_nat_gateway.nat[0].id
}


resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}


resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for s in aws_subnet.private : s.id]
  tags = merge(local.base_tags, { Name = "${local.name_prefix}-vpce-ssm" })
} 

# Basic security groups: bastion, eks_nodes, db
resource "aws_security_group" "bastion_sg" {
  name        = "${local.name_prefix}-sg-bastion"
  description = "Bastion SG - restrict to dev CIDR if provided"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.base_tags, { Name = "${local.name_prefix}-sg-bastion" })
}

resource "aws_security_group" "eks_nodes_sg" {
  name        = "${local.name_prefix}-sg-eks-nodes"
  description = "EKS worker nodes SG"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.base_tags, { Name = "${local.name_prefix}-sg-eks-nodes" })
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${local.name_prefix}-sg-db"
  description = "DB SG - allow mysql from eks nodes and optional dev cidr"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.base_tags, { Name = "${local.name_prefix}-sg-db" })
}

resource "aws_security_group_rule" "eks_to_db" {
  type                        = "ingress"
  from_port                   = 3306
  to_port                     = 3306
  protocol                    = "tcp"
  security_group_id           = aws_security_group.db_sg.id
  source_security_group_id    = aws_security_group.eks_nodes_sg.id
  description                 = "Allow EKS nodes to talk to DB"
}

resource "aws_security_group_rule" "devcidr_to_db" {
  count = var.access_cidr != "" ? 1 : 0
  type                        = "ingress"
  from_port                   = 3306
  to_port                     = 3306
  protocol                    = "tcp"
  security_group_id           = aws_security_group.db_sg.id
  cidr_blocks                 = [var.access_cidr]
  description                 = "CIDR DB access (dev only)"
}

# Optional : Tag outputs included below
