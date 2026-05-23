# Day 11 — Terraform Modules

## What is a Module?
A module is just a reusable folder of Terraform code. Instead of copy-pasting the same EC2 config in every project, you write it once as a module and call it wherever you need it.

Think of it like a function in programming — write once, use many times.

In real companies, teams have a library of modules (one for EC2, one for VPC, one for RDS etc.) and just call them as needed.

---

## Folder Structure We Built

```
day11-modules/
├── .gitignore
├── main.tf                  ← root config — calls the module
└── modules/
    └── ec2/
        ├── main.tf          ← the actual EC2 resource
        ├── variables.tf     ← what inputs the module accepts
        └── outputs.tf       ← what the module returns
```

The `modules/ec2/` folder IS the module. The root `main.tf` CALLS it.

---

## The Module Files

### modules/ec2/variables.tf
Defines what inputs the module accepts:
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the instance"
  type        = string
}

variable "ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}
```

### modules/ec2/main.tf
The actual resource — uses variables instead of hardcoded values:
```hcl
resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
```

### modules/ec2/outputs.tf
What the module returns to whoever calls it:
```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}
```

---

## The Root main.tf — Calling the Module

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

module "my_server" {
  source        = "./modules/ec2"    # path to the module folder
  instance_name = "terraform-day11"  # passing inputs to the module
  instance_type = "t3.micro"
}

output "server_ip" {
  value = module.my_server.public_ip  # using the module's output
}
```

### How calling a module works
- `source` — tells Terraform where the module folder is
- The other lines (`instance_name`, `instance_type`) — passing values into the module's variables
- `module.my_server.public_ip` — accessing the module's output

---

## What the apply output looks like with modules

```
module.my_server.aws_instance.this: Creating...
module.my_server.aws_instance.this: Creation complete after 13s [id=i-0abc30051e6dc346e]
```

Notice `module.my_server.aws_instance.this` — Terraform tells you exactly which module created this resource. This makes debugging much easier in large projects.

---

## Why Modules Matter

| Without modules | With modules |
|----------------|--------------|
| Copy-paste same EC2 config everywhere | Write once, call anywhere |
| Change instance type = edit every file | Change in one place |
| Hard to read large configs | Clean, organised, readable |
| Hard to share with teammates | Module = shareable building block |

---

## Good Habits We Followed Today
Created `.gitignore` FIRST before any `git add .`:
```bash
echo ".terraform/" > .gitignore
echo "*.tfstate" >> .gitignore
echo "*.tfstate.backup" >> .gitignore
git add .gitignore
git commit -m "init: add gitignore"
```
No state files ended up on GitHub. 

