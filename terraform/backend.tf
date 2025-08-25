terraform {
  backend "s3" {
    bucket = "zomatobackend"
    key    = "terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    }
  }

