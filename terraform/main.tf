resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key-${random_string.suffix.result}"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Store private key in AWS Systems Manager Parameter Store
resource "aws_ssm_parameter" "private_key" {
  name  = "/ec2/ssh-key/private"
  type  = "SecureString"
  value = tls_private_key.ec2_key.private_key_pem
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

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

resource "aws_instance" "web" {
  ami           = "ami-06dd92ecc74fdfb36"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name      = aws_key_pair.ec2_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y nginx
              systemctl start nginx
              mkdir -p /var/www/html
              chown -R www-data:www-data /var/www/html
              EOF
}