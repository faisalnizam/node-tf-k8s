terraform {
  required_version = ">= 0.13.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.69.0"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
    var.vpc_custom_tags,
  )
}

resource "aws_internet_gateway" "main" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
  )
}

data "aws_availability_zones" "all" {
  state            = var.availability_zone_state
  exclude_names    = var.availability_zone_exclude_names
  exclude_zone_ids = var.availability_zone_exclude_ids
}


resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags
  )
}

resource "aws_route" "default_internet" {
  count = var.create_public_subnets ? 1 : 0

  route_table_id         = aws_default_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  depends_on = [
    aws_internet_gateway.main,
    aws_default_route_table.default,
  ]
}

resource "aws_default_security_group" "default" {
  count = var.enable_default_security_group ? 1 : 0

  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress_rules
    content {
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      protocol         = ingress.value["protocol"]
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      description      = lookup(ingress.value, "description", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress_rules
    content {
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      protocol         = egress.value["protocol"]
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      description      = lookup(egress.value, "description", null)
    }
  }

  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
    var.security_group_tags,
  )
}

resource "aws_default_network_acl" "default" {
  count = var.apply_default_nacl_rules ? 1 : 0

  default_network_acl_id = aws_vpc.main.default_network_acl_id
  subnet_ids = (
    var.associate_default_nacl_to_subnets
    ? sort(concat(
      aws_subnet.public[*].id,
      aws_subnet.private-app[*].id,
      aws_subnet.private-persistence[*].id
    ))
    : []
  )

  dynamic "ingress" {
    for_each = var.default_nacl_ingress_rules
    content {
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      action          = ingress.value["action"]
      rule_no         = ingress.value["rule_no"]
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      icmp_code       = lookup(ingress.value, "icmp_code", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_nacl_egress_rules
    content {
      from_port       = egress.value["from_port"]
      to_port         = egress.value["to_port"]
      protocol        = egress.value["protocol"]
      action          = egress.value["action"]
      rule_no         = egress.value["rule_no"]
      cidr_block      = lookup(egress.value, "cidr_block", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      icmp_code       = lookup(egress.value, "icmp_code", null)
    }
  }

  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
  )
}


locals {
  num_public_subnets = var.create_public_subnets ? local.num_availability_zones : 0
}

resource "aws_subnet" "public" {
  count = local.num_public_subnets

  vpc_id = aws_vpc.main.id

  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = lookup(
    var.public_subnet_cidr_blocks,
    "AZ-${count.index}",
    cidrsubnet(var.cidr_block, var.public_subnet_bits, count.index),
  )
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    { Name = "${var.vpc_name}-public-${count.index}" },
    var.custom_tags,
    var.public_subnet_custom_tags,
  )
}

resource "aws_route_table" "public" {
  count = (
    var.create_public_subnets
    ? (var.one_route_table_public_subnets ? 1 : local.num_availability_zones)
    : 0
  )

  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = (
      var.one_route_table_public_subnets
      ? "${var.vpc_name}-public"
      : "${var.vpc_name}-public-${count.index}")
    },
    var.custom_tags,
  )
}

resource "aws_route" "internet" {
  count = (
    var.create_public_subnets
    ? (var.one_route_table_public_subnets ? 1 : local.num_availability_zones)
    : 0
  )

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.public,
  ]

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = local.num_public_subnets

  subnet_id = aws_subnet.public[count.index].id
  route_table_id = (
    var.one_route_table_public_subnets
    ? aws_route_table.public[0].id
    : aws_route_table.public[count.index].id
  )
}

resource "aws_eip" "nat" {
  count = var.create_public_subnets && var.use_custom_nat_eips == false ? var.num_nat_gateways : 0

  vpc        = true
  tags       = var.custom_tags
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat" {
  count = var.create_public_subnets ? var.num_nat_gateways : 0

  allocation_id = element(local.nat_eips, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = merge(
    { Name = "${var.vpc_name}-nat-gateway-${count.index}" },
    var.custom_tags,
    var.nat_gateway_custom_tags,
  )

  depends_on = [aws_internet_gateway.main]
}



locals {
  num_private_app_subnets = var.create_private_app_subnets ? local.num_availability_zones : 0
}

resource "aws_subnet" "private-app" {
  count = local.num_private_app_subnets

  vpc_id = aws_vpc.main.id

  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = lookup(
    var.private_app_subnet_cidr_blocks,
    "AZ-${count.index}",
    cidrsubnet(var.cidr_block, var.private_subnet_bits, count.index + local.private_spacing),
  )
  tags = merge(
    { Name = "${var.vpc_name}-private-app-${count.index}" },
    var.custom_tags,
    var.private_app_subnet_custom_tags,
  )
}

resource "aws_route_table" "private-app" {
  count = local.num_private_app_subnets

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.private_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-private-app-${count.index}" },
    var.custom_tags,
  )
}

resource "aws_route" "nat" {
  count = (
    var.num_nat_gateways == 0 || var.create_private_app_subnets == false || var.create_public_subnets == false
    ? 0
    : local.num_availability_zones
  )

  route_table_id         = aws_route_table.private-app[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)

  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.private-app,
  ]

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private-app" {
  count = local.num_private_app_subnets

  subnet_id      = aws_subnet.private-app[count.index].id
  route_table_id = aws_route_table.private-app[count.index].id
}



locals {
  num_private_persistence_subnets = var.create_private_persistence_subnets ? local.num_availability_zones : 0
}

resource "aws_subnet" "private-persistence" {
  count = local.num_private_persistence_subnets

  vpc_id = aws_vpc.main.id

  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = lookup(
    var.private_persistence_subnet_cidr_blocks,
    "AZ-${count.index}",
    cidrsubnet(var.cidr_block, var.persistence_subnet_bits, count.index + local.persistence_spacing),
  )
  tags = merge(
    { Name = "${var.vpc_name}-private-persistence-${count.index}" },
    var.custom_tags,
    var.private_persistence_subnet_custom_tags,
  )
}

resource "aws_route_table" "private-persistence" {
  count = local.num_private_persistence_subnets

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.persistence_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-private-persistence-${count.index}" },
    var.custom_tags,
  )
}

resource "aws_route" "private_persistence_nat" {
  count = (
    var.create_private_persistence_subnets && var.create_public_subnets && var.allow_private_persistence_internet_access && var.num_nat_gateways > 0
    ? local.num_availability_zones
    : 0
  )

  route_table_id         = element(aws_route_table.private-persistence.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)

  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.private-persistence,
  ]

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private-persistence" {
  count = local.num_private_persistence_subnets

  subnet_id      = aws_subnet.private-persistence[count.index].id
  route_table_id = aws_route_table.private-persistence[count.index].id
}



resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  policy       = var.s3_endpoint_policy
  tags         = var.custom_tags
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = var.create_vpc_endpoints && var.create_public_subnets ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public[0].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count = var.create_vpc_endpoints ? local.num_private_app_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.private-app[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_persistence" {
  count = var.create_vpc_endpoints ? local.num_private_persistence_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.private-persistence[count.index].id
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  policy       = var.dynamodb_endpoint_policy
  tags         = var.custom_tags
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
  count = var.create_vpc_endpoints && var.create_public_subnets ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.public[0].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
  count = var.create_vpc_endpoints ? local.num_private_app_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.private-app[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_persistence" {
  count = var.create_vpc_endpoints ? local.num_private_persistence_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.private-persistence[count.index].id
}


resource "null_resource" "vpc_ready" {
  depends_on = [
    aws_internet_gateway.main,
    aws_nat_gateway.nat,
    aws_route.internet,
    aws_route.nat,
  ]
}


locals {
  num_availability_zones = (
    var.num_availability_zones == null
    ? (
      var.availability_zone_ids == null
      ? length(data.aws_availability_zones.all.names)
      : length(var.availability_zone_ids)
    )
    : min(var.num_availability_zones, length(data.aws_availability_zones.all.names))
  )

  private_spacing     = var.private_subnet_spacing != null ? var.private_subnet_spacing : var.subnet_spacing
  persistence_spacing = var.persistence_subnet_spacing != null ? var.persistence_subnet_spacing : 2 * var.subnet_spacing
  nat_eips            = var.use_custom_nat_eips ? var.custom_nat_eips : aws_eip.nat[*].id
}
