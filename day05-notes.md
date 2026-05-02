# Day 5 — Private Subnets, NAT Gateway, Bastion Host

## What I built
- Private subnet (10.0.2.0/24) — no public IP, isolated from internet
- NAT Gateway in public subnet — lets private EC2 reach internet outbound only
- Bastion Host — jump server to SSH into private EC2
- Successfully SSHed: Mac → Bastion → Private EC2

## How it works
```
Mac → SSH → Bastion (public subnet, has public IP)
               → SSH → Private EC2 (private subnet, no public IP)
                           → NAT Gateway → Internet (outbound only)
```

## Key concepts
- Private subnet = no route to IGW = nobody can reach it from internet
- NAT Gateway = one-way door, outbound only, always in PUBLIC subnet
- Elastic IP = fixed public IP attached to NAT Gateway
- Bastion Host = only way to access private EC2

## What's left
- Verify NAT Gateway works: `curl http://checkip.amazonaws.com` from private EC2

## Commands
```bash
aws ec2 create-subnet --vpc-id VPC_ID --cidr-block 10.0.2.0/24
aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway --subnet-id PUBLIC_SUBNET --allocation-id EIP_ID
aws ec2 create-route --route-table-id RTB_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id NAT_ID
scp -i ~/.ssh/devops-key.pem ~/.ssh/devops-key.pem ec2-user@BASTION_IP:~/.ssh/
ssh -i ~/.ssh/devops-key.pem ec2-user@BASTION_IP
ssh -i /tmp/devops-key.pem ec2-user@PRIVATE_IP
```
