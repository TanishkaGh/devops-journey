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