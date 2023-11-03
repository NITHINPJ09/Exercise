terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

resource "tls_private_key" "new_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  filename = "private.pem"
  content  = tls_private_key.new_key.private_key_pem
}

data "tls_public_key" "new_key" {
  private_key_pem = tls_private_key.new_key.private_key_pem
}

resource "aws_key_pair" "new_key_pair" {
  key_name   = "public"
  public_key = data.tls_public_key.new_key.public_key_openssh
}

resource "aws_instance" "demo" {
  ami                    = "ami-00983e8a26e4c9bd9"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.new_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  tags = {
    Name = "Web Server"
  }
}

resource "aws_security_group" "instance_sg" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
}

output "public_ip" {
  value = aws_instance.demo.public_ip
}
