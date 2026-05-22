terraform {
  backend "s3" {
    bucket = "allanraymond-terraform-state"
    key    = "cloud-infra-project/terraform.tfstate"
    region = "us-east-1"
  }
}
