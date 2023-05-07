terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "cloud-tej"
    key    = "tfstate/terraform.tfstate"
    region = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  #access_key = "AKIAX3OD6IVG3SETPFDR"
  #secret_key = "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"
  assume_role {
     role_arn   = "arn:aws:iam::885726421659:role/cross-account"
     external_id = "12345"
}
}

 #add new





resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}
/* 1) first approch to create multiple subnet in diff avz 
resource "aws_subnet" "useast1a" {

vpc_id = aws_vpc.main.id
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"

tags = {
 Name = "us-east-1a"
}
}

resource "aws_subnet" "useast1b" {

vpc_id = aws_vpc.main.id
cidr_block = "10.0.2.0/24"
availability_zone = "us-east-1b"

tags = {
 Name = "us-east-1b"
}
}

resource "aws_subnet" "useast1c" {

vpc_id = aws_vpc.main.id
cidr_block = "10.0.3.0/24"
availability_zone = "us-east-1c"

tags = {
 Name = "us-east-1c"
}
}
*/

// 2 nd approch to create multiple subnet in diff avz but it create in same avz 

/*
variable "subnets_cidr" {
    description = "Total number of subnets"
    type = list(string)
    default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]   
}

resource "aws_subnet" "sub" {
  for_each = toset(var.subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = each.key
  availability_zone = "us-east-1a"

  tags = {
    Name = "us-east-1a"
  }
}
*/

// 3rd approch using type=map we create  multiple subnet in diff avz

variable "subnets_cidr" {
    description = "Total number of subnets"
    type = map(string)
    default = {
    "us-east-1a" = "10.0.1.0/24", 
    "us-east-1b" = "10.0.2.0/24", 
    "us-east-1c" = "10.0.3.0/24"
        
    }
}

resource "aws_subnet" "sub" {
  for_each = var.subnets_cidr
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  availability_zone = each.key

  tags = {
    Name = each.key
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "routetable"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
