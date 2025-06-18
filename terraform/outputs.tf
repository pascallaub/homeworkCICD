output "ec2_ip" {
  value = aws_instance.web_server.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ec2_key.private_key_pem
  sensitive = true
}

output "key_name" {
  value = aws_key_pair.ec2_key_pair.key_name
}
