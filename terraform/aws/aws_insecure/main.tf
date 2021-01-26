terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  access_key = "AKIAQIU2DJ23C3RMAUVF"
  secret_key = "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"
}

resource "aws_security_group" "i" {
  name = "instance-i"
  description = "Security group for instance i"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "i" {
  ami = "ami-0db62131f0f997f26"
  instance_type = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.i.id ]
  metadata_options {
    http_tokens = "required"
  }
}