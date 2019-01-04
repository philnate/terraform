terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket         = "${get_aws_account_id()}-terraformstate"
      key            = "account/${path_relative_to_include()}/terraform.tfstate"
      region         = "eu-central-1"
      encrypt        = true
      dynamodb_table = "terraform-lock-table"
    }
  }
}
