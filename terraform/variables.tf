variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "react-cicd-terraform-state-1750250738"  
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}