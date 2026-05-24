resource "aws_instance" "main" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = var.instance_name
  }
}