terraform {
  backend "s3" {
    bucket = "backend88364" # Replace with your actual S3 bucket name
    key    = "terraform.tfstate"
    region = "us-east-1" # ap-south-1
  }
}