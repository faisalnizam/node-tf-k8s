module "vpc_app" {
  source = "../modules/terraform-aws-vpc/vpc-app"

  vpc_name   = var.vpcname
  aws_region = var.region

  cidr_block = var.cidr

  num_nat_gateways = 3


  public_subnet_cidr_blocks = {}

  private_app_subnet_cidr_blocks = {}

  private_persistence_subnet_cidr_blocks = {}

  custom_tags = {
    Name = "swvl-vpc"
  }

  public_subnet_custom_tags = {
    Name = "prod-public"
  }

  private_app_subnet_custom_tags = {
    Name = "prod-private-app"
  }

  private_persistence_subnet_custom_tags = {
    Name = "prod-private-persistence"
  }

  nat_gateway_custom_tags = {
    Name = "prod-nat-gateway"
  }
}
