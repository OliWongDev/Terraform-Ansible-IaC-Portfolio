terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

variable "cloudflare_api_token" {
  description = "The Cloudflare API token for authentication"
  type        = string
}


provider "aws" {
  region = "ap-southeast-2" # specify your desired region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "OliVPC"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"     # Subnet range within the VPC CIDR block
  availability_zone       = "ap-southeast-2a" # Choose an AZ in your region
  map_public_ip_on_launch = true              # Automatically assign public IPs to instances in this subnet

  tags = {
    Name = "OliSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "OliInternetGateway"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Route all internet traffic to the IGW
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "OliRouteTable"
  }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress = [
    {
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "Allow SSH access"
    },
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "Allow HTTP access"
    },
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "Allow HTTPS access"
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "Allow all outbound traffic"
    }
  ]

  tags = {
    Name = "OliSecurityGroup"
  }
}


resource "aws_instance" "main" {
  ami             = "ami-09e143e99e8fa74f9" # Ubuntu AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.main.id]

  tags = {
    Name = "OliInstance"
  }
}

# Elastic IP
resource "aws_eip" "main" {
  instance = aws_instance.main.id

  tags = {
    Name = "OliElasticIP"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Create a DNS record
resource "cloudflare_dns_record" "root" {
  zone_id = "07d2248f52b014b7165fecf930f75f30"
  comment = "Domain verification record Oli"
  content = aws_eip.main.public_ip
  name = "@"
  proxied = false
  ttl = 3600
  type = "A"
}

resource "cloudflare_dns_record" "www" {
  zone_id = "07d2248f52b014b7165fecf930f75f30"
  comment = "Domain verification record Oli"
  content = aws_eip.main.public_ip
  name    = "www"
  proxied = false
  ttl     = 3600
  type    = "A"
}


