output "public_subnets_network_acl_id" {
  value = length(aws_network_acl.public_subnets) > 0 ? aws_network_acl.public_subnets[0].id : null
}

output "private_app_subnets_network_acl_id" {
  value = length(aws_network_acl.private_app_subnets) > 0 ? aws_network_acl.private_app_subnets[0].id : null
}

output "private_persistence_subnets_network_acl_id" {
  value = length(aws_network_acl.private_persistence_subnets) > 0 ? aws_network_acl.private_persistence_subnets[0].id : null
}
