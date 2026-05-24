# Day 12 — Full AWS Setup with Terraform

## What we built today
Everything we used to build manually by clicking in the AWS console — VPC, subnet, internet gateway, route table, security group, EC2 — we rebuilt it all with Terraform. 

One command to build everything. One command to tear it all down.

---

## File Structure

```
day12-full-setup/
├── .gitignore
├── main.tf           ← provider config
├── variables.tf      ← all input values
├── vpc.tf            ← VPC, subnet, IGW, route table
├── security-group.tf ← firewall rules
├── ec2.tf            ← the server
└── outputs.tf        ← what to print after apply
```

Splitting into multiple files keeps things organised. Terraform reads all `.tf` files in the folder together.

---

## variables.tf
```hcl
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_name" {
  type    = string
  default = "terraform-day12"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
```

---

## main.tf
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
  region = var.aws_region
}
```

---

## vpc.tf
5 resources in one file — VPC, subnet, internet gateway, route table, and the association between subnet and route table:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "day12-vpc" }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  tags = { Name = "day12-subnet" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "day12-igw" }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "day12-rt" }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}
```

### How resources reference each other
- `aws_subnet.main.id` — Terraform knows the subnet ID even before it's created. It figures out the order automatically.
- `aws_internet_gateway.main.id` — same idea. This is called implicit dependency.

---

## security-group.tf
```hcl
resource "aws_security_group" "main" {
  name   = "day12-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## ec2.tf
```hcl
resource "aws_instance" "main" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = var.instance_name
  }
}
```

Notice: the EC2 is placed inside the subnet and attached to the security group — all by referencing other resources.

---

## outputs.tf
```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}

output "instance_id" {
  value = aws_instance.main.id
}

output "public_ip" {
  value = aws_instance.main.public_ip
}
```

---

## The result
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:
vpc_id      = "vpc-0abc123..."
subnet_id   = "subnet-0abc123..."
instance_id = "i-0abc123..."
public_ip   = "13.201.x.x"
```

7 AWS resources created in one command. What used to take 20 minutes of console clicking now takes 30 seconds.

---

## Key concept — Implicit Dependencies
Terraform figures out the order to create resources automatically. You don't tell it "create VPC first, then subnet." It reads your references (`aws_vpc.main.id`) and figures it out on its own.


