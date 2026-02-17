provider "aws" {
  region = "ap-south-1"
}

# 1. Create VPC
resource "aws_vpc" "flipkart_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "flipkart_vpc"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "flipkart_igw" {
  vpc_id = aws_vpc.flipkart_vpc.id
  tags = {
    Name = "flipkart_igw"
  }
}

# 3. Create Subnet
resource "aws_subnet" "flipkart_subnet" {
  vpc_id                  = aws_vpc.flipkart_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "flipkart_subnet"
  }
}

# 4. Create Route Table
resource "aws_route_table" "flipkart_rt" {
  vpc_id = aws_vpc.flipkart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.flipkart_igw.id
  }

  tags = {
    Name = "flipkart_rt"
  }
}

# 5. Associate Route Table to Subnet
resource "aws_route_table_association" "flipkart_rta" {
  subnet_id      = aws_subnet.flipkart_subnet.id
  route_table_id = aws_route_table.flipkart_rt.id
}

# 6. Security Group
resource "aws_security_group" "app_sg" {
  name        = "flipkart_sg"
  description = "Allow SSH and all inbound/outbound"
  vpc_id      = aws_vpc.flipkart_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flipkart_sg"
  }
}

# 7. EC2 Instances
resource "aws_instance" "app_server" {
  ami             = "ami-0ec3f93cf7ecd1eeb"
  instance_type   = "t2.micro"
  key_name        = "devops"
  count           = 2
  subnet_id       = aws_subnet.flipkart_subnet.id
  security_groups = [aws_security_group.app_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "flipkart_server"
  }

  user_data = file("sample.sh")
}

# 8. Outputs
output "vpc_id" {
  value = aws_vpc.flipkart_vpc.id
}

output "subnet_id" {
  value = aws_subnet.flipkart_subnet.id
}

output "route_table_id" {
  value = aws_route_table.flipkart_rt.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.flipkart_igw.id
}

output "public_ips" {
  value = [for instance in aws_instance.app_server : instance.public_ip]
}

output "private_ips" {
  value = [for instance in aws_instance.app_server : instance.private_ip]
}
