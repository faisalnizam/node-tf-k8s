
variable "vpc_id" {
  description = "The id of the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC (e.g. stage, prod)"
  type        = string
}

variable "num_subnets" {
  description = "The number of each type of subnet (public, private, private persistence) created in this VPC. Typically, this is equal to the number of availability zones in the current region. We should be able to compute this automatically, but due to a Terraform bug, we can't: https://github.com/hashicorp/terraform/issues/3888"
  type        = number
}

variable "public_subnet_ids" {
  description = "A list of IDs of the public subnets in the VPC"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "A list of IDs of the private app subnets in the VPC"
  type        = list(string)
}

variable "private_persistence_subnet_ids" {
  description = "A list of IDs of the private persistence subnets in the VPC"
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "A list of CIDR blocks used by the public subnets in the VPC"
  type        = list(string)
}

variable "private_app_subnet_cidr_blocks" {
  description = "A list of CIDR blocks used by the private app subnets in the VPC"
  type        = list(string)
}

variable "private_persistence_subnet_cidr_blocks" {
  description = "A list of CIDR blocks used by the private persistence subnets in the VPC"
  type        = list(string)
}


variable "allow_access_from_mgmt_vpc" {
  description = "If set to true, the network ACLs will allow incoming requests from the Mgmt VPC CIDR block defined in var.mgmt_vpc_cidr_block."
  type        = bool
  default     = false
}

variable "mgmt_vpc_cidr_block" {
  description = "The CIDR block of the Mgmt VPC. All subnets will allow connections from this CIDR block. Only used if var.allow_access_from_mgmt_vpc is set to true."
  type        = string
  default     = null
}

variable "vpc_ready" {
  description = "Use this variable to ensure the Network ACL does not get created until the VPC is ready. This can help to work around a Terraform or AWS issue where trying to create certain resources, such as Network ACLs, before the VPC's Gateway and NATs are ready, leads to a huge variety of eventual consistency bugs. You should typically point this variable at the vpc_ready output from the Gruntwork VPCs."
  type        = string
  default     = null
}

variable "custom_tags" {
  description = "A map of tags to apply to the Network ACLs created by this module. The key is the tag name and the value is the tag value. Note that the tag 'Name' is automatically added by this module but may be optionally overwritten by this variable."
  type        = map(string)
  default     = {}
}

variable "create_public_subnet_nacls" {
  description = "If set to false, this module will NOT create the NACLs for the public subnet tier. This is useful for VPCs that only need private subnets."
  type        = bool
  default     = true
}

variable "create_private_app_subnet_nacls" {
  description = "If set to false, this module will NOT create the NACLs for the private app subnet tier."
  type        = bool
  default     = true
}

variable "create_private_persistence_subnet_nacls" {
  description = "If set to false, this module will NOT create the NACLs for the private persistence subnet tier."
  type        = bool
  default     = true
}

variable "private_app_allow_inbound_ports_from_cidr" {
  description = "A map of unique names to client IP CIDR block and inbound ports that should be exposed in the private app subnet tier nACLs. This is useful when exposing your service on a privileged port with an NLB, where the address isn't translated."
  type = map(
    object({
      client_cidr_block = string

      rule_number = number

      protocol = string

      from_port = number
      to_port   = number
    })
  )
  default = {}
}

variable "create_resources" {
  description = "If you set this variable to false, this module will not create any resources. This is used as a workaround because Terraform does not allow you to use the 'count' parameter on modules. By using this parameter, you can optionally create or not create the resources within this module."
  type        = bool
  default     = true
}
