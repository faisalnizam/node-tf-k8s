module "minikube" {
  source = "../modules/terraform-aws-server/" 

  name             = local.minikube_name
  instance_type    = "m3.medium" 
  ami              = local.ami
  keypair_name     = local.key_pair
  user_data_base64 = data.cloudinit_config.cloud_init.rendered
  attach_eip       = false

  vpc_id                   = module.vpc_app.vpc_id
  subnet_id                = module.vpc_app.public_subnet_ids[0]
  allow_ssh_from_cidr_list = ["0.0.0.0/0"]

  tags = {
    Name = "Kube Server"
  }
}

data "cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bastion-default-cloud-init"
    content_type = "text/x-shellscript"
    content      = local.user_data
  }
}

locals {
  user_data = file("${path.module}/user-data.sh")
}

