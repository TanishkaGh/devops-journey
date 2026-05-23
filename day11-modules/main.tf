terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "my_server" {
  source        = "./modules/ec2"
  instance_name = "terraform-day11"
  instance_type = "t3.micro"
}

output "server_ip" {
  value = module.my_server.public_ip
}