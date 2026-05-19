terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "cloud-infra-project/terraform.tfstate"
    region = "us-east-1"
  }
}
