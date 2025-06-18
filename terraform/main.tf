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

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create web directory
    mkdir -p /var/www/html
    chown -R nginx:nginx /var/www/html
    
    # Basic index.html
    echo "<h1>Web Server Deployed via CI/CD</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "web-server"
  }
}