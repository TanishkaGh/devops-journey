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