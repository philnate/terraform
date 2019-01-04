provider "aws" {
  region = "${var.region}"
}

provider "aws" {
  alias = "replica"
  region = "${var.replica_region}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
