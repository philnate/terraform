data "aws_caller_identity" "current" {}

data "aws_kms_alias" "s3" {
  name = "alias/aws/s3"
}

data "aws_kms_alias" "s3_replica" {
  provider = "aws.replica"
  name = "alias/aws/s3"
}
