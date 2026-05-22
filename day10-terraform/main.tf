terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "my_server" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}