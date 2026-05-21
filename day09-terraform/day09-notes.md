# Day 9 — Terraform Basics

## What is Terraform
Terraform is Infrastructure as Code (IaC). Instead of clicking in the AWS console or running CLI commands, you write a `.tf` file describing what you want, and Terraform builds it.

**Why it matters:** Every DevOps job requires Terraform. It's how real teams manage infrastructure — reproducible, version-controlled, reviewable.

## The 4 core commands

| Command | What it does |
|---------|-------------|
| `terraform init` | Downloads the required plugins (AWS provider etc.) |
| `terraform plan` | Dry run — shows what WILL be created, no changes yet |
| `terraform apply` | Actually creates the infrastructure |
| `terraform destroy` | Tears everything down |

Always run in this order: init → plan → apply → destroy.

## What we built

`main.tf` — provisions a t3.micro EC2 in Mumbai:

```hcl
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

resource "aws_instance" "my_server" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-day09"
  }
}
```

## File structure explained

- `terraform {}` — which plugins to download
- `provider "aws"` — connect to AWS, which region
- `resource "aws_instance" "my_server"` — create an EC2 instance named "my_server"
- `ami` — the OS image (Amazon Linux 2023, Mumbai)
- `instance_type` — size of the server
- `tags` — label it in the AWS console

## What `terraform plan` output means

```
Plan: 1 to add, 0 to change, 0 to destroy.
```
This is the important line. Always read it before typing `yes` to apply.

Fields marked `(known after apply)` = AWS will assign these values after the instance launches (like public IP, instance ID etc.)

## Mistake we hit

**Error:** `t2.micro is not eligible for Free Tier` in Mumbai  
**Why:** AWS quietly changed free tier eligibility for t2.micro in ap-south-1  
**Fix:** Changed to `t3.micro` — also free tier eligible in Mumbai

## The big shift from Days 1–8

- Days 1–8: built infrastructure by hand (console clicks, CLI commands)
- Day 9+: write a file → Terraform builds it

The file IS the infrastructure. Delete the instance, run `terraform apply` again — it comes back identical. This is why teams use it.
