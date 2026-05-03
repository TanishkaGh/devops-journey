#Day06- FIXED WHATEVER WENT WRONG YESTERDAY.
Problem 1: curl timed out for 3 days
What happened: curl http://checkip.amazonaws.com from the private EC2 kept timing out — "Could not connect to server."
Why: The private subnet's route table had a 0.0.0.0/0 route pointing to an OLD NAT Gateway that had already been deleted. Every time we deleted and recreated the NAT Gateway, the route table kept the old dead ID. Traffic had directions but the destination didn't exist.
How we fixed it: Used replace-route instead of create-route to update the existing route to point to the new NAT Gateway ID. This is the fix that made everything work on Day 5.
Lesson: When you delete and recreate a NAT Gateway, always update the route table to point to the new one. The route table NEVER updates automatically.

Problem 2: SSH key permission errors on Bastion
What happened: After copying the key to the Bastion with scp, the .ssh folder had wrong ownership (root instead of ec2-user). Every chmod command failed with "Permission denied."
Why: The scp command copied the file but the .ssh directory permissions were restrictive, causing ownership issues.
How we fixed it: Copied the key to /tmp/ instead (a folder with open permissions), fixed ownership there, and used /tmp/devops-key.pem as the key path for SSH.
Lesson: /tmp/ is always writable by everyone. When you hit permission walls, /tmp/ is a useful escape hatch for temporary files.

Problem 3: Ran AWS CLI from inside EC2 server
What happened: Tried running aws ec2 create-vpc from inside the EC2 server and got "Unable to locate credentials."
Why: AWS CLI credentials (aws configure) were set up on your Mac, not on the server. The server doesn't have your AWS credentials.
How we fixed it: Always run AWS CLI commands from your Mac terminal, not from inside the EC2.
Lesson: Your Mac = where you control AWS. EC2 server = the thing you're controlling. Never confuse the two.