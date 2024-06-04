provider "aws" {
  region = "us-west-1"  # specify the AWS region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH Key Pair
resource "aws_key_pair" "login" {
  key_name   = "login-key"
  public_key = file("~/.ssh/id_rsa.pub")  # path to your SSH public key
}

# EC2 Instance
resource "aws_instance" "host" {
  ami           = "ami-08012c0a9ee8e21c4"  # specify a valid AMI ID for your region
  instance_type = "t2.2xlarge"

  key_name               = aws_key_pair.login.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "TerraformExample"
  }

  # Add a block device mapping to use the instance store for /mnt
  root_block_device {
    volume_size = 128  # GB
    volume_type = "gp3"
  }
}

output "instanceip" {
  description = "IP addredd for public endpoint"
  value = aws_instance.host.public_ip
}