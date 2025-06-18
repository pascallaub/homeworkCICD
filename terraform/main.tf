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

# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2
resource "aws_security_group" "web_sg" {
  name_prefix = "web-server-sg"
  description = "Security group for web server"

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

  tags = {
    Name = "web-server-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    
    # Start and enable nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create web directory with correct permissions
    mkdir -p /var/www/html
    chown -R www-data:www-data /var/www/html
    chmod 755 /var/www/html
    
    # Create basic index.html
    echo "<h1>Web Server Deployed via CI/CD</h1><p>Ubuntu Server - $(date)</p>" > /var/www/html/index.html
    chown www-data:www-data /var/www/html/index.html
    
    # Ensure nginx starts on boot
    systemctl enable nginx
  EOF

  tags = {
    Name = "web-server-ubuntu"
  }
}