variable "vpcname" {
  description = "vpc name to be given"
}

variable "region" {
  description = "region to use to create resources"
}

variable "cidr" {
  description = "cidr to be userd"
}

variable "profile" {
  description = "profile to use for creation of resources"
}


variable "attach_eip" {
  description = "Determines if an Elastic IP (EIP) will be created for this instance. Must be set to a boolean (not a string!) true or false value."
  type        = bool
  default     = false
}

