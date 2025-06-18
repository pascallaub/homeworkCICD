terraform {
  backend "s3" {
    bucket         = "terraform-state-jonas-2025"
    key            = "terraform.tfstate"
    region         = "eu-central-1"           
  }
}
