resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id, aws_security_group.ssh.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
  }))
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-web-server"
    Type = "WebServer"
  }

  lifecycle {
    create_before_destroy = true
  }
}
