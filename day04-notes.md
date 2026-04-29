Day 4- AWS Networking — VPC, Subnets, Security Groups
VPC (Virtual Private Cloud)
Your own private section of AWS. Like having your own plot of land inside Amazon's data centre. Everything you build goes inside it. Completely isolated from other AWS customers.

Subnet
A smaller section inside your VPC. Like dividing your plot into rooms.

Public subnet = has access to the internet (for web servers)
Private subnet = no direct internet access (for databases, internal services)

Internet Gateway (IGW)
The door between your VPC and the internet. Without it, nothing inside your VPC can talk to the outside world even if it's in a public subnet.

Security Group
A firewall for your EC2 instance. Controls what traffic is allowed in (inbound) and out (outbound). Like a bouncer at the door of each server.

Route Table
A set of directions that tells traffic where to go. Every subnet needs a route table. Without the right routes, traffic doesn't know how to get anywhere even if the IGW exists.

CIDR Notation 
CIDR (Classless Inter-Domain Routing) is how you define a range of IP addresses.
Format: IP_ADDRESS/NUMBER
The number after the / tells you how many bits are fixed:

/16 = first 16 bits fixed = 10.0.X.X = 65,536 possible addresses (large network)
/24 = first 24 bits fixed = 10.0.1.X = 256 possible addresses (smaller network)