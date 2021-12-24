
terraform {
  required_version = ">= 0.12.26"
}



resource "aws_network_acl" "public_subnets" {
  count = (var.create_resources && var.create_public_subnet_nacls) ? 1 : 0

  depends_on = [null_resource.vpc_ready]

  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
  tags = merge(
    { "Name" = "${var.vpc_name}-public-subnets" },
    var.custom_tags,
  )
}

module "public_subnet_allow_all_inbound_and_outbound" {
  source = "../network-acl-inbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.public_subnets) > 0 ? aws_network_acl.public_subnets[0].id : null
  ingress_rule_number = 100
  egress_rule_number  = 100

  protocol          = "all"
  inbound_from_port = 0
  inbound_to_port   = 65535

  inbound_cidr_blocks     = ["0.0.0.0/0"]
  num_inbound_cidr_blocks = var.create_public_subnet_nacls ? 1 : 0
}



resource "aws_network_acl" "private_app_subnets" {
  count = (var.create_resources && var.create_private_app_subnet_nacls) ? 1 : 0

  depends_on = [null_resource.vpc_ready]

  vpc_id     = var.vpc_id
  subnet_ids = var.private_app_subnet_ids
  tags = merge(
    { "Name" = "${var.vpc_name}-private-app-subnets" },
    var.custom_tags,
  )
}

resource "aws_network_acl_rule" "private_app_subnet_all_traffic_from_self" {
  count          = (var.create_resources && var.create_private_app_subnet_nacls) ? var.num_subnets : 0
  network_acl_id = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  rule_number    = 100 + (count.index * 5)
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = element(var.private_app_subnet_cidr_blocks, count.index)
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_app_subnet_all_traffic_to_self" {
  count          = (var.create_resources && var.create_private_app_subnet_nacls) ? var.num_subnets : 0
  network_acl_id = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  rule_number    = 100 + (count.index * 5)
  egress         = true
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = element(var.private_app_subnet_cidr_blocks, count.index)
}

resource "aws_network_acl_rule" "private_app_subnet_all_traffic_from_public_subnet" {
  count          = (var.create_resources && var.create_private_app_subnet_nacls && var.create_public_subnet_nacls) ? var.num_subnets : 0
  network_acl_id = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  rule_number    = 200 + (count.index * 5)
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = element(var.public_subnet_cidr_blocks, count.index)
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_app_allow_inbound_from_client_cidr" {
  for_each       = var.create_resources ? var.private_app_allow_inbound_ports_from_cidr : {}
  network_acl_id = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  egress         = false
  rule_action    = "allow"

  rule_number = each.value.rule_number
  protocol    = each.value.protocol
  cidr_block  = each.value.client_cidr_block
  from_port   = each.value.from_port
  to_port     = each.value.to_port
}

module "private_app_subnet_all_traffic_from_mgmt_vpc" {
  source = "../network-acl-inbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  ingress_rule_number = 300
  egress_rule_number  = 300

  protocol          = "all"
  inbound_from_port = 0
  inbound_to_port   = 65535

  inbound_cidr_blocks     = [var.mgmt_vpc_cidr_block]
  num_inbound_cidr_blocks = var.create_private_app_subnet_nacls && var.allow_access_from_mgmt_vpc ? 1 : 0
}


module "private_app_subnet_all_outbound_tcp_traffic" {
  source = "../network-acl-outbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  ingress_rule_number = 400
  egress_rule_number  = 400

  protocol = "tcp"

  outbound_from_port = 0
  outbound_to_port   = 65535

  outbound_cidr_blocks     = ["0.0.0.0/0"]
  num_outbound_cidr_blocks = var.create_private_app_subnet_nacls ? 1 : 0
}

module "private_app_subnet_outbound_dns_traffic" {
  source = "../network-acl-outbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  ingress_rule_number = 997
  egress_rule_number  = 997

  protocol           = "udp"
  outbound_from_port = 53
  outbound_to_port   = 53

  outbound_cidr_blocks     = ["0.0.0.0/0"]
  num_outbound_cidr_blocks = var.create_private_app_subnet_nacls ? 1 : 0
}

module "private_app_subnet_inbound_ntp_traffic" {
  source = "../network-acl-inbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  ingress_rule_number = 998
  egress_rule_number  = 998

  protocol          = "udp"
  inbound_from_port = 123
  inbound_to_port   = 123

  inbound_cidr_blocks     = ["0.0.0.0/0"]
  num_inbound_cidr_blocks = var.create_private_app_subnet_nacls ? 1 : 0
}

module "private_app_subnet_outbound_ntp_traffic" {
  source = "../network-acl-outbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
  ingress_rule_number = 999
  egress_rule_number  = 999

  protocol           = "udp"
  outbound_from_port = 123
  outbound_to_port   = 123

  outbound_cidr_blocks     = ["0.0.0.0/0"]
  num_outbound_cidr_blocks = var.create_private_app_subnet_nacls ? 1 : 0
}

resource "aws_network_acl" "private_persistence_subnets" {
  count = (var.create_resources && var.create_private_persistence_subnet_nacls) ? 1 : 0

  depends_on = [null_resource.vpc_ready]

  vpc_id     = var.vpc_id
  subnet_ids = var.private_persistence_subnet_ids
  tags = merge(
    { "Name" = "${var.vpc_name}-private-persistence-subnets" },
    var.custom_tags,
  )
}

module "private_persistence_subnet_all_outbound_tcp_traffic" {
  source = "../network-acl-outbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  ingress_rule_number = 400
  egress_rule_number  = 400

  protocol = "tcp"

  outbound_from_port = 0
  outbound_to_port   = 65535

  outbound_cidr_blocks     = ["0.0.0.0/0"]
  num_outbound_cidr_blocks = var.create_private_persistence_subnet_nacls ? 1 : 0
}

resource "aws_network_acl_rule" "private_persistence_subnet_all_traffic_from_self" {
  count          = (var.create_resources && var.create_private_persistence_subnet_nacls) ? var.num_subnets : 0
  network_acl_id = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  rule_number    = 100 + (count.index * 5)
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = element(var.private_persistence_subnet_cidr_blocks, count.index)
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_persistence_subnet_all_traffic_to_self" {
  count          = (var.create_resources && var.create_private_persistence_subnet_nacls) ? var.num_subnets : 0
  network_acl_id = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  rule_number    = 100 + (count.index * 5)
  egress         = true
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = element(var.private_persistence_subnet_cidr_blocks, count.index)
}

module "private_persistence_subnet_all_traffic_from_private_app_subnet" {
  source = "../network-acl-inbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  ingress_rule_number = 200
  egress_rule_number  = 200

  protocol          = "all"
  inbound_from_port = 0
  inbound_to_port   = 65535

  inbound_cidr_blocks     = var.private_app_subnet_cidr_blocks
  num_inbound_cidr_blocks = var.create_private_persistence_subnet_nacls && var.create_private_app_subnet_nacls ? var.num_subnets : 0
}

module "private_persistence_subnet_all_traffic_from_mgmt_vpc" {
  source = "../network-acl-inbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  ingress_rule_number = 300
  egress_rule_number  = 300

  protocol          = "all"
  inbound_from_port = 0
  inbound_to_port   = 65535

  inbound_cidr_blocks     = [var.mgmt_vpc_cidr_block]
  num_inbound_cidr_blocks = var.create_private_persistence_subnet_nacls && var.allow_access_from_mgmt_vpc ? 1 : 0
}

module "private_persistence_subnet_outbound_dns_traffic" {
  source = "../network-acl-outbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  ingress_rule_number = 997
  egress_rule_number  = 997

  protocol           = "udp"
  outbound_from_port = 53
  outbound_to_port   = 53

  outbound_cidr_blocks     = ["0.0.0.0/0"]
  num_outbound_cidr_blocks = var.create_private_persistence_subnet_nacls ? 1 : 0
}

module "private_persistence_subnet_inbound_ntp_traffic" {
  source = "../network-acl-inbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  ingress_rule_number = 998
  egress_rule_number  = 998

  protocol          = "udp"
  inbound_from_port = 123
  inbound_to_port   = 123

  inbound_cidr_blocks     = ["0.0.0.0/0"]
  num_inbound_cidr_blocks = var.create_private_persistence_subnet_nacls ? 1 : 0
}

module "private_persistence_subnet_outbound_ntp_traffic" {
  source = "../network-acl-outbound"

  create_resources = var.create_resources

  network_acl_id      = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
  ingress_rule_number = 999
  egress_rule_number  = 999

  protocol           = "udp"
  outbound_from_port = 123
  outbound_to_port   = 123

  outbound_cidr_blocks     = ["0.0.0.0/0"]
  num_outbound_cidr_blocks = var.create_private_persistence_subnet_nacls ? 1 : 0
}

resource "null_resource" "vpc_ready" {
  count = var.create_resources ? 1 : 0

  triggers = {
    vpc_ready = var.vpc_ready
  }
}
