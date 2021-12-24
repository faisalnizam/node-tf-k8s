
resource "aws_instance" "instance" {
  ami                     = var.ami
  instance_type           = var.instance_type
  iam_instance_profile    = aws_iam_instance_profile.instance.name
  key_name                = var.keypair_name
  vpc_security_group_ids  = concat([aws_security_group.instance.id], var.additional_security_group_ids)
  subnet_id               = var.subnet_id
  user_data               = var.user_data
  user_data_base64        = var.user_data_base64
  tenancy                 = var.tenancy
  source_dest_check       = var.source_dest_check
  monitoring              = var.monitoring
  disable_api_termination = var.disable_api_termination
  private_ip              = var.private_ip
  secondary_private_ips   = var.secondary_private_ips

  tags = merge(
    { "Name" = var.name },
    var.tags,
  )

  ebs_optimized = var.ebs_optimized

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
    tags                  = var.root_volume_tags
  }

  depends_on = [time_sleep.iam_instance_profile_wait_30s]
}



resource "aws_iam_role" "instance" {
  count                 = var.create_iam_role ? 1 : 0
  name                  = var.iam_role_name == "" ? var.name : var.iam_role_name
  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy.json
  force_detach_policies = var.force_detach_policies

  tags = var.tags
}

data "aws_iam_role" "existing" {
  count = var.create_iam_role ? 0 : 1
  name  = local.iam_role_name
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.assume_role_principals
    }
  }
}

resource "aws_iam_instance_profile" "instance" {
  name       = local.iam_role_name
  role       = local.iam_role_name
  depends_on = [time_sleep.iam_role_wait_30s]
}

resource "time_sleep" "iam_role_wait_30s" {
  count           = var.create_iam_role ? 1 : 0
  create_duration = "30s"
  depends_on      = [aws_iam_role.instance]
}

resource "time_sleep" "iam_instance_profile_wait_30s" {
  create_duration = "30s"
  depends_on      = [aws_iam_instance_profile.instance]
}

resource "aws_security_group" "instance" {
  name_prefix            = local.security_group_name
  description            = "Security Group for ${local.security_group_name}"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_security_group_rules_on_delete

  tags = merge(
    {
      "Name" = local.security_group_name
    },
    var.tags,
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_outbound_all" {
  count             = var.allow_all_outbound_traffic ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}


resource "aws_security_group_rule" "allow_inbound_ssh_from_cidr" {
  count             = signum(length(var.allow_ssh_from_cidr_list))
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allow_ssh_from_cidr_list
  security_group_id = aws_security_group.instance.id
}

resource "aws_security_group_rule" "allow_inbound_ssh_from_security_group" {
  count                    = length(var.allow_ssh_from_security_group_ids)
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.allow_ssh_from_security_group_ids[count.index]
  security_group_id        = aws_security_group.instance.id
}


resource "aws_security_group_rule" "allow_inbound_rdp_from_cidr" {
  count             = signum(length(var.allow_rdp_from_cidr_list))
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = var.allow_rdp_from_cidr_list
  security_group_id = aws_security_group.instance.id
}

resource "aws_security_group_rule" "allow_inbound_rdp_from_security_group" {
  count                    = length(var.allow_rdp_from_security_group_ids)
  type                     = "ingress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "tcp"
  source_security_group_id = var.allow_rdp_from_security_group_ids[count.index]
  security_group_id        = aws_security_group.instance.id
}


resource "aws_eip" "instance" {
  count    = var.attach_eip ? 1 : 0
  instance = aws_instance.instance.id
  vpc      = true

  tags = merge(
    {
      "Name" : var.name
    },
    var.tags,
  )

  provisioner "local-exec" {
    command = "echo 'Sleeping 15 seconds to work around EIP propagation bug in Terraform' && sleep 15"
  }
}


resource "aws_route53_record" "instance" {
  count = signum(length(var.dns_zone_id))

  zone_id = var.dns_zone_id
  name    = var.dns_name
  type    = var.dns_type
  ttl     = var.dns_ttl
  records = [var.dns_uses_private_ip ? aws_eip.instance[0].private_ip : aws_eip.instance[0].public_ip]
}


locals {
  security_group_name = var.security_group_name == "" ? var.name : var.security_group_name
  iam_role_name       = length(aws_iam_role.instance) > 0 ? aws_iam_role.instance[0].name : var.iam_role_name
}
