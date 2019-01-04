terragrunt = {

  include {
    path = "${find_in_parent_folders()}"
  }

  terraform {
    source = "${get_tfvars_dir()}/../../modules//account"

  }
}

region = "eu-central-1"
replica_region = "eu-west-3"
bucket_retention = "365"
