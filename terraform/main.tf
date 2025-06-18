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
  name  = "/ec2/ssh-key/private-${random_string.suffix.result}"
  type  = "SecureString"
  value = tls_private_key.ec2_key.private_key_pem
  
  tags = {
    Environment = "deployment"
  }
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
    
    # Start and enable nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create web directory with correct permissions
    mkdir -p /var/www/html
    chown -R nginx:nginx /var/www/html
    chmod 755 /var/www/html
    
    # Create basic index.html
    echo "<h1>Web Server Deployed via CI/CD</h1><p>$(date)</p>" > /var/www/html/index.html
    chown nginx:nginx /var/www/html/index.html
    
    # Configure nginx to serve from /var/www/html
    cat > /etc/nginx/nginx.conf <<'EOL'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /var/www/html;
        index        index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }
    }
}
EOL
    
    # Restart nginx to apply config
    systemctl restart nginx
    
    # Ensure nginx starts on boot
    systemctl enable nginx
  EOF

  tags = {
    Name = "web-server"
  }
}