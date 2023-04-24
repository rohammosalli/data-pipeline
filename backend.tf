# terraform {
#   backend "s3" {
#     bucket = "terraform-pipe-state-heartbit"
#     key    = "terraform.tfstate"
#     region = "eu-central-1"
#     endpoint = "https://s3-eu-central-1.amazonaws.com"
#   }
# }
 module "tf-state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  bucket  = "terraform-pipe-state-heartbit"
 }
