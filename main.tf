#########################
# VPC
#########################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "prod-vpc"
  }
}

#########################
# INTERNET GATEWAY
#########################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "prod-igw"
  }
}

#########################
# PUBLIC SUBNETS
#########################

resource "aws_subnet" "public" {
  count = 3

  vpc_id = aws_vpc.main.id

  cidr_block = element(
    [
      "10.0.1.0/24",
      "10.0.2.0/24",
      "10.0.3.0/24"
    ],
    count.index
  )

  availability_zone = element(
    [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c"
    ],
    count.index
  )

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

#########################
# ROUTE TABLE
#########################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

#########################
# ROUTE ASSOCIATION
#########################

resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#########################
# SECURITY GROUP
#########################

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH HTTP HTTPS"
  vpc_id      = aws_vpc.main.id

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

  ingress {
    from_port   = 443
    to_port     = 443
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

#########################
# EC2 INSTANCES
#########################

resource "aws_instance" "web" {
  count = 2

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id = aws_subnet.public[count.index].id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "web-server-${count.index + 1}"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}