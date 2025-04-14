terraform {
  backend "s3" {
    bucket         = "acs730-final-project-041401332025"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
  }
}
