variable "region" {
  description = "primary AWS region"
  type        = "string"
}

variable "replica_region" {
  description = "Where to replicate the S3 buckets to"
  type        = "string"
}

variable "bucket_retention" {
  description = "Number of days non current versions of bucket versions are kept"
  type        = "string"
}
