terraform {
  backend "s3" {
    bucket         = "react-cicd-terraform-state-1750250738"
    key            = "terraform.tfstate"
    region         = "eu-central-1"           
  }
}
