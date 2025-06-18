resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-keypair-${random_id.key_suffix.hex}"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-keypair-${random_id.key_suffix.hex}"
  }
}

resource "random_id" "key_suffix" {
  byte_length = 4
}
