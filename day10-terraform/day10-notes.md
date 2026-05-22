# Day 10 — Terraform Variables, Outputs & State File

## Why today matters
Yesterday we wrote a working Terraform config. Today we made it professional — reusable, informative, and safe.

---

## Variables

### The problem with hardcoding
In Day 9, values like `"ap-south-1"` and `"t3.micro"` were written directly in `main.tf`. If you wanted to reuse the config for a different region, you'd have to hunt and replace every value manually.

### The fix — variables.tf
Create a separate file called `variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-day10"
}
```

### Reference variables in main.tf using `var.`
```hcl
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
```

Now if you want to change the region, you change it in one place — `variables.tf` — and everything updates.

---

## Outputs

### The problem without outputs
After `terraform apply`, you have no idea what the public IP of your EC2 is. You'd have to go to the AWS console to find it.

### The fix — outputs.tf
Create a file called `outputs.tf`:

```hcl
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.my_server.id
}

output "public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.my_server.public_ip
}

output "instance_name" {
  description = "The name tag of the instance"
  value       = var.instance_name
}
```

After `terraform apply`, Terraform prints this directly in the terminal:
```
Outputs:

instance_id = "i-0ab19570417c43f93"
instance_name = "terraform-day10"
public_ip = "13.201.115.251"
```

In real projects, outputs are used to pass values between modules, print database connection strings, load balancer URLs, and more.

---

## The State File

### What it is
`terraform.tfstate` is a JSON file Terraform creates automatically. It's Terraform's memory — it tracks everything Terraform has created (instance IDs, IPs, all details).

When you run `terraform plan` or `terraform apply`, Terraform compares your `.tf` files against this state file to figure out what needs to change.

### 3 rules — never break these

1. **Never edit it manually** — you'll corrupt it and Terraform loses track of your infrastructure
2. **Never delete it** — Terraform will think nothing exists and try to create everything from scratch
3. **Never commit it to GitHub** — it can contain sensitive data like passwords and keys

### Add to .gitignore
```bash
echo "*.tfstate" >> .gitignore
echo "*.tfstate.backup" >> .gitignore
```

---

## Final file structure for a proper Terraform project


day10-terraform/
├── main.tf          # the actual resources
├── variables.tf     # all input variables
├── outputs.tf       # what to print after apply
└── .gitignore       # ignore .terraform/ and *.tfstate
