output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by subnet name."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by subnet name."
  value       = module.vpc.public_subnet_ids
}

output "private_route_table_id" {
  description = "Private route table ID."
  value       = module.vpc.private_route_table_id
}

output "public_route_table_id" {
  description = "Public route table ID, when public subnets exist."
  value       = module.vpc.public_route_table_id
}

output "network_acl_ids" {
  description = "Network ACL IDs keyed by logical name."
  value       = { for name, acl in aws_network_acl.this : name => acl.id }
}
