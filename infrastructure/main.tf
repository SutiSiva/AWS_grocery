terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "eu-central-1"
}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "sutivpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "terraformsutivpc" }
}

# -------------------------------
# Public Subnet
# -------------------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.sutivpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"

  tags = { Name = "public-subnet" }
}

# -------------------------------
# Private Subnets (RDS)
# -------------------------------
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.sutivpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-central-1b"

  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.sutivpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-central-1c"

  tags = { Name = "private-subnet-2" }
}

# -------------------------------
# Internet Gateway
# -------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.sutivpc.id

  tags = { Name = "terraform-igw" }
}

# -------------------------------
# Public Route Table
# -------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.sutivpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------
# EC2 Security Group
# -------------------------------
resource "aws_security_group" "ec2_sg" {
  name   = "grocerymate-ec2-sg"
  vpc_id = aws_vpc.sutivpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "grocerymate-ec2-sg" }
}

# -------------------------------
# EC2 Instance (IAM Instance Profile kommt aus s3.tf!)
# -------------------------------
resource "aws_instance" "app" {
  ami                         = "ami-06ee6255945a96aba"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = "suti-ec2-key"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name  # kommt aus s3.tf

  tags = { Name = "grocerymate-ec2" }
}

# -------------------------------
# Output
# -------------------------------
output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}