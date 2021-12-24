output "arn" {
  value = aws_instance.instance.arn
}

output "id" {
  value = aws_instance.instance.id
}

output "name" {
  value = var.name
}

output "public_ip" {
  value = var.attach_eip ? aws_eip.instance.*.public_ip[0] : aws_instance.instance.public_ip
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

output "secondary_private_ips" {
  value = aws_instance.instance.secondary_private_ips
}

output "fqdn" {
  value = join(",", aws_route53_record.instance.*.fqdn)
}

output "security_group_id" {
  value = aws_security_group.instance.id
}

output "iam_role_id" {
  value = (
    length(aws_iam_role.instance) > 0
    ? aws_iam_role.instance[0].id
    : (
      length(data.aws_iam_role.existing) > 0
      ? data.aws_iam_role.existing[0].id
      : var.iam_role_name
    )
  )
}

output "iam_role_name" {
  value = length(aws_iam_role.instance) > 0 ? aws_iam_role.instance[0].name : var.iam_role_name
}

output "iam_role_arn" {
  value = (
    length(aws_iam_role.instance) > 0
    ? aws_iam_role.instance[0].arn
    : (
      length(data.aws_iam_role.existing) > 0
      ? data.aws_iam_role.existing[0].arn
      : null
    )
  )
}

output "instance_ip" {
  value = aws_instance.instance.public_ip
}

output "ami" {
  value = aws_instance.instance.ami
}
