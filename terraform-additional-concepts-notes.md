# Terraform — Advanced Concepts
### Remote State + tfvars + terraform import

---

## Concept 1 — Remote State (S3 + DynamoDB)

### The Problem
State file sitting on your Mac = bad.
- Mac crashes → state gone → Terraform has no memory
- Team of 5 → everyone has different state → chaos
- Two people run simultaneously → state corrupted

### The Solution
Store state in S3. Everyone accesses the same file. Never gets lost.

```
Before: Mac → terraform.tfstate (local, risky)
After:  S3  → terraform.tfstate (remote, safe, shared)
```

### What We Built

**S3 Bucket** — stores the state file
```bash
aws s3api create-bucket --bucket tanishka-terraform-state --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1
aws s3api put-bucket-versioning --bucket tanishka-terraform-state --versioning-configuration Status=Enabled
```
Versioning = like screenshot history. If state gets corrupted, go back to previous version.

**DynamoDB Table** — prevents simultaneous runs
```bash
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region ap-south-1
```
When Terraform runs → writes "I'm busy" to DynamoDB → others must wait → no corruption.

**Backend config in main.tf**
```hcl
terraform {
  backend "s3" {
    bucket         = "tanishka-terraform-state"
    key            = "day12/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```
- `key` = path inside bucket where state file lives
- `encrypt = true` = state file encrypted (contains sensitive IDs)

**Migrate state**
```bash
terraform init -migrate-state
```
Reinitializes Terraform and moves existing state to S3.

### Important
State file only written to S3 after `terraform apply`. `terraform plan` is just a preview — writes nothing.

---

## Concept 2 — tfvars (Dev/Prod Environments)

### The Problem
Same infrastructure, different environments. Without tfvars you'd need duplicate code for dev and prod. Messy.

### The Solution
Write code once. Pass different values files for each environment.

### The Pizza Analogy
- Chef (Terraform code) = same
- Order slip (tfvars file) = different per customer
- Result = different pizza, same process

### What We Built

**dev.tfvars**
```hcl
instance_type = "t3.micro"
instance_name = "dev-server"
vpc_cidr      = "10.0.0.0/16"
subnet_cidr   = "10.0.1.0/24"
```

**prod.tfvars**
```hcl
instance_type = "t3.small"
instance_name = "prod-server"
vpc_cidr      = "10.1.0.0/16"
subnet_cidr   = "10.1.1.0/24"
```

**How to use**
```bash
terraform plan -var-file="dev.tfvars"   # preview dev environment
terraform plan -var-file="prod.tfvars"  # preview prod environment
terraform apply -var-file="dev.tfvars"  # create dev environment
```

### Why Different IP Ranges?
Dev = `10.0.0.0/16`, Prod = `10.1.0.0/16`

If both used same range and you ever connected them, they'd conflict — like two streets with the same address. Different ranges keep them separate.

---

## Concept 3 — terraform import

### The Problem
You join a company. Previous engineer created VPC, EC2, security groups manually in AWS console. No Terraform was used. You want to manage everything with Terraform going forward.

If you write Terraform code and run `terraform plan` → it says "7 resources to add" → because Terraform doesn't know they already exist. Running `terraform apply` would create duplicates.

### The Solution
`terraform import` — tell Terraform "this resource already exists in AWS, add it to your state file."

### Syntax
```bash
terraform import RESOURCE_TYPE.RESOURCE_NAME AWS_ID
```

**Examples:**
```bash
# Import a VPC
terraform import aws_vpc.main vpc-0ccbf4c7c46d4e9ef

# Import an EC2
terraform import aws_instance.main i-0f32a1f7fd4e1162e

# Import a security group
terraform import aws_security_group.main sg-0a1b2c3d4e5f
```

After importing → `terraform plan` shows `0 to add, 0 to change` → Terraform now knows everything exists.

### When You'd Use This
- Joining a company with existing manual AWS infrastructure
- State file got accidentally deleted
- Someone created something manually you want Terraform to manage


---

## Mental Map

```
Remote State:
  S3 bucket    = where state file lives (safe, shared)
  DynamoDB     = lock system (one person at a time)
  backend "s3" = tells Terraform to use remote state
  State written only on terraform apply, not terraform plan

tfvars:
  Same code + different .tfvars = different environments
  dev.tfvars  = small, cheap, 10.0.0.0/16
  prod.tfvars = larger, 10.1.0.0/16
  terraform plan/apply -var-file="env.tfvars"

terraform import:
  Existing resource in AWS → bring into Terraform state
  terraform import aws_vpc.main vpc-ID
  Use when: taking over manual infrastructure, lost state file
```

---

## All Terraform Commands Reference

```bash
terraform init              # initialize, download providers
terraform init -migrate-state  # reinitialize + move state to new backend
terraform plan              # preview changes
terraform plan -var-file="dev.tfvars"  # preview with specific values
terraform apply             # create/update resources
terraform apply -var-file="dev.tfvars"  # apply with specific values
terraform destroy           # delete all resources
terraform state list        # list resources in state
terraform import TYPE.NAME ID  # import existing resource into state
```