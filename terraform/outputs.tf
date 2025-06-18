output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "ssh_user" {
  description = "SSH username for the EC2 instance"
  value       = "ubuntu"
}

output "ssh_private_key" {
  description = "Private SSH key for the EC2 instance"
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}

output "website_url" {
  description = "URL of the deployed website"
  value       = "http://${aws_instance.web.public_ip}"
}
