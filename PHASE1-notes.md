# Phase 1 — Complete Notes
### Linux + AWS Foundations · Days 1–5 · Every command, concept, problem and fix

---

## The Big Picture — What Phase 1 Taught You

```
Your Mac
    │
    │ SSH
    ▼
EC2 Server (Linux) ← you control this from your terminal
    │
    └── Lives inside a VPC (your private AWS network)
          ├── Public Subnet → Internet Gateway → Internet
          └── Private Subnet → NAT Gateway → Internet (outbound only)
```

---

# DAY 1 — Setup + Linux Filesystem

## Concepts
- **EC2** = a computer you rent from AWS, running in a data centre
- **SSH** = Secure Shell — encrypted tunnel from your Mac to the remote server
- **IP Address** = unique address of every device on the internet (like a home address)
- **Public IP** = visible on the internet, changes every stop/start on EC2
- **Private IP** = only visible inside the VPC (10.x.x.x), stays the same
- **Linux filesystem** = everything is a file, organised in a tree starting from `/`

## Key filesystem locations
```
/           root — top of everything
/etc        config files for the system and services
/var/log    all log files — go here when something breaks
/home       home directories for all users (/home/ec2-user)
/tmp        temporary files — deleted on reboot
/usr        installed software and libraries
/bin        essential commands (ls, cd, cat live here)
/proc       live view of running kernel — not a real folder
```

## Commands

**Setup:**
```bash
git --version                          # check git installed
python3 --version                      # check python installed
aws configure                          # connect CLI to AWS (run on Mac)
aws sts get-caller-identity            # verify CLI connected correctly
```

**Key file setup:**
```bash
mkdir -p ~/.ssh                        # create .ssh folder
mv ~/Downloads/devops-key.pem ~/.ssh/  # move key to right place
chmod 400 ~/.ssh/devops-key.pem        # lock key — AWS requires this
ls -la ~/.ssh/devops-key.pem           # verify: should show -r--------
```

**SSH:**
```bash
ssh -i ~/.ssh/devops-key.pem ec2-user@IP    # connect to server
exit                                         # disconnect from server
```

**Navigation:**
```bash
pwd                     # where am I?
cd /path                # go to folder
cd ~                    # go home
cd ..                   # go up one level
ls                      # list files
ls -la                  # list with permissions, hidden files, details
```

**File operations:**
```bash
touch file.txt                      # create empty file
echo "text" > file.txt              # write text to file (overwrites)
echo "text" >> file.txt             # append text to file
cat file.txt                        # print file contents
head -10 file.txt                   # first 10 lines
tail -20 file.txt                   # last 20 lines
tail -f file.txt                    # follow file live (Ctrl+C to stop)
nano file.txt                       # open in editor (Ctrl+X to save)
rm file.txt                         # delete file
rm -r folder/                       # delete folder and contents
cp source dest                      # copy file
mv old new                          # move or rename file
find / -name "filename"             # search for file by name
```

**System info:**
```bash
whoami                  # current username
uname -a                # OS and kernel info
df -h                   # disk usage (human readable)
free -h                 # memory usage
top                     # live process viewer (q to exit)
```

## Problems + Fixes
| Problem | Fix |
|---------|-----|
| `chmod 400` needed before SSH | Always run after downloading .pem key |
| IP changes every stop/start | Check AWS console for new IP each session |
| Ran AWS CLI from inside EC2 | Always run AWS CLI from Mac terminal |

---

# DAY 2 — Permissions, Users, Groups, Services, Logs

## Concepts
- **Permissions** = who can read/write/execute each file
- **Owner** = user who owns the file
- **Group** = a collection of users
- **Service** = a program running in the background continuously (nginx, sshd)
- **Process** = any running program — every service is a process

## File permissions explained
```
-rw-r--r--
│ │   │   └── others: r only
│ │   └─────── group: r only
│ └─────────── owner: rw
└────────────── type: - file, d directory

r = read  = 4
w = write = 2
x = execute = 1

Common combinations:
400 = r--------  owner read only (SSH keys)
644 = rw-r--r--  normal files
755 = rwxr-xr-x  scripts/executables
770 = rwxrwx---  shared team folders
777 = rwxrwxrwx  NEVER use in production
000 = ---------- nobody can do anything
```

## Commands

**Permissions:**
```bash
chmod 644 file.txt              # change permissions
chmod 755 script.sh             # make executable
chmod -R 755 folder/            # recursive (all files inside too)
chown user:group file           # change owner and group
chown -R ec2-user:ec2-user ~/.ssh  # recursive ownership change
```

**Users:**
```bash
sudo useradd username           # create user
sudo passwd username            # set password
sudo su - username              # switch to user (- loads their environment)
exit                            # go back to previous user
id username                     # show user's UID, GID, groups
cat /etc/passwd                 # list all users on system
```

**Groups:**
```bash
sudo groupadd groupname         # create group
sudo usermod -aG groupname user # add user to group (-a = append, don't remove existing)
groups username                 # show user's groups
cat /etc/group                  # list all groups
```

**Shared folder pattern:**
```bash
sudo mkdir /shared
sudo chown ec2-user:devteam /shared
sudo chmod 770 /shared
# Now both ec2-user and any devteam member can read/write
```

**Processes:**
```bash
ps aux                          # all running processes
ps aux | grep nginx             # filter processes by name
top                             # live process viewer
htop                            # better live viewer (install with dnf)
kill PID                        # stop process by ID
sudo kill -9 PID                # force kill (use when normal kill fails)
```

**Services (systemctl):**
```bash
sudo systemctl start nginx      # start
sudo systemctl stop nginx       # stop
sudo systemctl restart nginx    # stop then start (use after config changes)
sudo systemctl enable nginx     # auto-start on reboot
sudo systemctl disable nginx    # don't auto-start
sudo systemctl status nginx     # check if running
systemctl is-active nginx       # returns active or inactive (use in scripts)
```

**Package manager:**
```bash
sudo dnf install nginx -y       # install package
sudo dnf remove nginx -y        # uninstall
sudo dnf update -y              # update all packages
sudo dnf search nginx           # search for package
```

**Log analysis:**
```bash
tail -20 /var/log/nginx/access.log      # last 20 lines
tail -f /var/log/nginx/access.log       # follow live
grep "200" /var/log/nginx/access.log    # lines containing 200
grep -v "200" file.log                  # lines NOT containing 200
grep -r "error" /var/log/               # search recursively in folder
awk '{print $1, $4, $9}' access.log    # extract columns 1, 4, 9
awk '{print $9}' access.log | sort | uniq -c  # count status codes
```

**Nginx log format explained:**
```
::1 - - [27/Apr/2026:09:15:50 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.17.0"
 │           │                          │               │   │
 IP        timestamp                  request        status size
```

## Problems + Fixes
| Problem | Fix |
|---------|-----|
| `sudo dnf install git` fails on EC2 | Use `sudo dnf install git -y` |
| Permission denied reading log files | Add `sudo` before the command |
| Ran git commands on EC2 instead of Mac | Git commands run on Mac, Linux commands on EC2 |

---

# DAY 3 — Bash Scripting

## Concepts
- **Script** = text file containing commands that run automatically in sequence
- **Shebang** = `#!/bin/bash` — always first line, tells Linux how to run the file
- **Variable** = name that stores a value, reuse with `$`
- **Command substitution** = `$(command)` — run command and use its output
- **Conditional** = if/else — make decisions based on conditions
- **Loop** = repeat commands for each item in a list
- **Function** = reusable named block of code
- **Cron** = scheduler — runs scripts automatically at set times

## Script structure
```bash
#!/bin/bash                    # always first line

NAME="Tanishka"                # variable — NO spaces around =
DATE=$(date)                   # command substitution
echo "Hello $NAME"             # use variable with $

if [ $DISK -gt 80 ]; then      # conditional
    echo "Warning"
else
    echo "OK"
fi                             # closes if (if backwards)

for SERVICE in nginx sshd; do  # loop
    echo "$SERVICE"
done                           # closes loop

check() {                      # function
    echo "Checking $1"         # $1 = first argument passed in
}
check nginx                    # call function
```

## Number comparison operators
```
-gt   greater than
-lt   less than
-ge   greater than or equal to
-le   less than or equal to
-eq   equal to
-ne   not equal to
```

## String comparison operators
```
=     equal
!=    not equal
-z    empty string
-n    not empty string
```

## Commands
```bash
touch script.sh                 # create script file
nano script.sh                  # write script
chmod 755 script.sh             # give execute permission
./script.sh                     # run script

# File writing in scripts
echo "text" > file.txt          # overwrite
echo "text" >> file.txt         # append (use for logs)

# Cron
sudo dnf install cronie -y      # install cron
sudo systemctl start crond      # start cron service
sudo systemctl enable crond     # auto-start on reboot
crontab -e                      # edit cron jobs
crontab -l                      # list cron jobs
crontab -r                      # remove all cron jobs

# Pipe crontab directly (avoids editor issues)
echo "* * * * * /home/ec2-user/script.sh" | crontab -
```

## Cron syntax
```
* * * * * command
│ │ │ │ └── day of week (0=Sunday)
│ │ │ └──── month (1-12)
│ │ └────── day of month (1-31)
│ └──────── hour (0-23)
└────────── minute (0-59)

* = every
* * * * * = every minute
0 9 * * * = every day at 9am
0 9 * * 1 = every Monday at 9am
```

## The health check script we built
```bash
#!/bin/bash
LOG_FILE="/tmp/healthcheck.log"
DATE=$(date)

echo "=== Health Check: $DATE ===" >> $LOG_FILE

check_service() {
    if systemctl is-active --quiet $1; then
        echo "OK: $1 is running" >> $LOG_FILE
    else
        echo "WARNING: $1 is stopped" >> $LOG_FILE
    fi
}

check_disk() {
    USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ $USAGE -gt 80 ]; then
        echo "WARNING: Disk at $USAGE%" >> $LOG_FILE
    else
        echo "OK: Disk at $USAGE%" >> $LOG_FILE
    fi
}

check_service nginx
check_service sshd
check_disk
echo "Complete. Results in $LOG_FILE"
```

## Problems + Fixes
| Problem | Fix |
|---------|-----|
| Curly quotes `"` breaking script | Always type quotes manually in terminal, never paste from chat |
| `y y y y` printing endlessly from heredoc | Ctrl+C to stop, recreate file with nano |
| `crontab -e` opening vim with wrong entry | Use pipe method: `echo "..." \| crontab -` |
| `export EDITOR=nano` — nano opened and closed instantly | Use pipe method instead |

## Key rules
1. Always start with `#!/bin/bash`
2. No spaces around `=` in variables
3. Always `chmod 755` before running
4. Use `>>` not `>` for log files (>> appends, > overwrites)
5. Ctrl+C stops any stuck command

---

# DAY 4 — AWS Networking (Public Subnet)

## Concepts
- **VPC** = your private section of AWS, isolated from other customers
- **Subnet** = smaller network inside your VPC (like rooms in a building)
- **Public subnet** = has route to IGW = instances can reach internet directly
- **Private subnet** = no route to IGW = isolated, no direct internet
- **Internet Gateway (IGW)** = the door between your VPC and the internet
- **Route Table** = directions for traffic — tells it where to go
- **Security Group** = firewall per instance — controls inbound/outbound traffic
- **CIDR** = IP address range notation: /16 = large (65,536 IPs), /24 = small (256 IPs)

## CIDR explained
```
10.0.0.0/16  = VPC    = 65,536 addresses (10.0.0.0 to 10.0.255.255)
10.0.1.0/24  = Subnet = 256 addresses    (10.0.1.0 to 10.0.1.255)
10.0.2.0/24  = Subnet = 256 addresses    (10.0.2.0 to 10.0.2.255)

/16 = 32-16 = 16 bits free = 2^16 = 65,536
/24 = 32-24 = 8 bits free  = 2^8  = 256
More bits fixed = smaller network
```

## Build order — always follow this sequence
```
1. Create VPC
2. Create subnet(s)
3. Create Internet Gateway
4. Attach IGW to VPC
5. Create Route Table
6. Add route: 0.0.0.0/0 → IGW
7. Associate Route Table with subnet
8. Create Security Group
9. Add inbound rules (port 22, port 80)
10. Launch EC2
```

## Commands
```bash
# VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text

# Subnet
aws ec2 create-subnet --vpc-id VPC_ID --cidr-block 10.0.1.0/24 --query Subnet.SubnetId --output text

# Internet Gateway
aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text
aws ec2 attach-internet-gateway --vpc-id VPC_ID --internet-gateway-id IGW_ID

# Route Table
aws ec2 create-route-table --vpc-id VPC_ID --query RouteTable.RouteTableId --output text
aws ec2 create-route --route-table-id RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id IGW_ID
aws ec2 associate-route-table --route-table-id RTB_ID --subnet-id SUBNET_ID

# Security Group
aws ec2 create-security-group --group-name my-sg --description "My SG" --vpc-id VPC_ID --query GroupId --output text
aws ec2 authorize-security-group-ingress --group-id SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

# EC2
aws ec2 run-instances --image-id AMI_ID --instance-type t3.micro --subnet-id SUBNET_ID --security-group-ids SG_ID --associate-public-ip-address --key-name devops-key --query 'Instances[0].InstanceId' --output text

# Get public IP
aws ec2 describe-instances --instance-ids INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# Terminate
aws ec2 terminate-instances --instance-ids INSTANCE_ID

# Get correct AMI for Mumbai
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023*" "Name=architecture,Values=x86_64" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text

# List resources
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
aws ec2 describe-subnets --filter "Name=vpc-id,Values=VPC_ID" --query 'Subnets[*].[SubnetId,CidrBlock]' --output table
aws ec2 describe-security-groups --filter "Name=vpc-id,Values=VPC_ID" --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
```

## Problems + Fixes
| Problem | Fix |
|---------|-----|
| `Unable to locate credentials` on EC2 | Run all AWS CLI commands from Mac, not inside EC2 |
| `t2.micro not eligible for Free Tier` in Mumbai | Use `t3.micro` instead |
| No output from CLI command | Silence = success in AWS CLI |
| `Resource.AlreadyAssociated` | Association already exists — ignore and move on |

---

# DAY 5 — AWS Networking (Private Subnet + NAT + Bastion)

## Concepts
- **Private Subnet** = no route to IGW, no public IP, isolated from internet
- **NAT Gateway** = lets private instances reach internet outbound only — one-way door
- **Elastic IP** = fixed public IP that doesn't change — NAT Gateway needs one
- **Bastion Host** = public EC2 used as jump server to access private EC2
- **replace-route** = update existing route (use instead of create-route when route exists)

## Architecture
```
Internet
    │
IGW (attached to VPC)
    │
Public Subnet 10.0.1.0/24
    ├── Bastion Host (public IP) ← SSH entry point from Mac
    └── NAT Gateway (Elastic IP) ← handles private subnet outbound traffic
            │
            Private Subnet 10.0.2.0/24
                └── Private EC2 (NO public IP)
                      └── curl → NAT Gateway → Internet ✓
                      └── Internet → Private EC2 ✗ (blocked)
```

## Commands
```bash
# Elastic IP
aws ec2 allocate-address --domain vpc --query AllocationId --output text
aws ec2 release-address --allocation-id EIPALLOC_ID      # always do this after deleting NAT GW
aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output text

# NAT Gateway (always in PUBLIC subnet)
aws ec2 create-nat-gateway --subnet-id PUBLIC_SUBNET_ID --allocation-id EIPALLOC_ID --query NatGateway.NatGatewayId --output text
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=VPC_ID" --query 'NatGateways[?State!=`deleted`].State' --output text
aws ec2 delete-nat-gateway --nat-gateway-id NAT_ID

# Private route table
aws ec2 create-route-table --vpc-id VPC_ID --query RouteTable.RouteTableId --output text
aws ec2 create-route --route-table-id PRIVATE_RTB_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id NAT_ID
aws ec2 associate-route-table --route-table-id PRIVATE_RTB_ID --subnet-id PRIVATE_SUBNET_ID

# Fix broken route (update existing route to new NAT GW)
aws ec2 replace-route --route-table-id RTB_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id NEW_NAT_ID

# Check route tables
aws ec2 describe-route-tables --filter "Name=vpc-id,Values=VPC_ID" --query 'RouteTables[*].[RouteTableId,Associations[0].SubnetId,Routes[0].NatGatewayId]' --output table

# Bastion → Private EC2
scp -i ~/.ssh/devops-key.pem ~/.ssh/devops-key.pem ec2-user@BASTION_IP:~/.ssh/
ssh -i ~/.ssh/devops-key.pem ec2-user@BASTION_PUBLIC_IP
# Then from inside Bastion:
sudo cp ~/.ssh/devops-key.pem /tmp/devops-key.pem
sudo chmod 400 /tmp/devops-key.pem
sudo chown ec2-user:ec2-user /tmp/devops-key.pem
ssh -i /tmp/devops-key.pem ec2-user@PRIVATE_IP

# Verify NAT works (from inside private EC2)
curl http://checkip.amazonaws.com
# Returns NAT Gateway's Elastic IP — proves outbound traffic works
```

## Public vs Private route table difference
| | Public Route Table | Private Route Table |
|--|--|--|
| 0.0.0.0/0 → | Internet Gateway | NAT Gateway |
| Internet can reach in? | Yes | No |
| Can reach internet? | Yes (directly) | Yes (via NAT only) |

## Cleanup order (always follow this)
```bash
# 1. Terminate EC2 instances first
aws ec2 terminate-instances --instance-ids ID1 ID2

# 2. Delete NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id NAT_ID

# 3. Wait until deleted
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=VPC_ID" --query 'NatGateways[?State!=`deleted`].State' --output text

# 4. Release Elastic IP only AFTER NAT Gateway is deleted
aws ec2 release-address --allocation-id EIPALLOC_ID
```

## Problems + Fixes
| Problem | Why | Fix |
|---------|-----|-----|
| `curl` timed out for 3 days | Private route table pointed to deleted NAT GW | `replace-route` to update to new NAT GW ID |
| SSH key permission errors on Bastion | `.ssh` folder wrong ownership after scp | Copy key to `/tmp/` and use that path |
| `RouteAlreadyExists` error | Route already exists from previous attempt | Use `replace-route` not `create-route` |
| NAT Gateway costs money | Charged ~$0.045/hour | Always delete after every session |
| Elastic IP costs money if unattached | AWS charges for unattached EIPs | Always release after deleting NAT GW |

---

# Complete AWS CLI Quick Reference

## Describe (check what exists)
```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
aws ec2 describe-subnets --filter "Name=vpc-id,Values=VPC_ID" --query 'Subnets[*].[SubnetId,CidrBlock]' --output table
aws ec2 describe-instances --filter "Name=vpc-id,Values=VPC_ID" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
aws ec2 describe-security-groups --filter "Name=vpc-id,Values=VPC_ID" --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
aws ec2 describe-route-tables --filter "Name=vpc-id,Values=VPC_ID" --query 'RouteTables[*].[RouteTableId,Associations[0].SubnetId]' --output table
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=VPC_ID" --query 'NatGateways[*].[NatGatewayId,State]' --output table
aws ec2 describe-addresses --query 'Addresses[*].[AllocationId,PublicIp]' --output table
aws ec2 describe-internet-gateways --filter "Name=attachment.vpc-id,Values=VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text
```

---

# Mental Map — Everything Together

```
PHASE 1 FOUNDATIONS

Linux
├── Filesystem: / → /etc /var/log /home /tmp
├── Permissions: chmod (numbers), chown (owner)
├── Users/Groups: useradd, groupadd, usermod -aG
├── Services: systemctl start/stop/enable/status
├── Logs: tail, grep, awk
└── Scripts: #!/bin/bash, variables, if/else, loops, functions, cron

AWS Networking
├── VPC → your private building
├── Subnet → rooms inside (public or private)
├── IGW → front door to internet
├── Route Table → directions for traffic
├── Security Group → bouncer at each server's door
├── NAT Gateway → mail room (outbound only, in PUBLIC subnet)
├── Elastic IP → fixed public address for NAT GW
└── Bastion Host → receptionist, jump server into private EC2

Traffic flows:
Mac → SSH → Bastion (public subnet) → SSH → Private EC2
Private EC2 → NAT GW → IGW → Internet (outbound only)
Internet → IGW → ✗ cannot reach private EC2 directly
```

---

