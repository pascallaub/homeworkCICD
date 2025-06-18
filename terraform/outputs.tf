output "ec2_ip" {
  value = aws_instance.web_server.public_ip
}

output "private_key_ssm_parameter" {
  value = aws_ssm_parameter.private_key.name
}

output "key_name" {
  value = aws_key_pair.ec2_key_pair.key_name
}
