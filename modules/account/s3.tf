# Create replication role
resource "aws_iam_role" "replication" {
  name               = "photos-bucket-replication-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name   = "photos-bucket-replication-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.backup.arn}",
        "${aws_s3_bucket.backup.arn}/*"
      ]
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Condition": {
        "StringLike": {
          "kms:ViaService": "s3.${var.region}.amazonaws.com",
          "kms:EncryptionContext:aws:s3:arn": [
            "${aws_s3_bucket.backup.arn}/*"
          ]
        }
      },
      "Resource": [
        "${data.aws_kms_alias.s3.arn}"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.replica.arn}/*"
    },
    {
      "Action": [
        "kms:Encrypt"
      ],
      "Effect": "Allow",
      "Condition": {
        "StringLike": {
          "kms:ViaService": "s3.${var.replica_region}.amazonaws.com",
          "kms:EncryptionContext:aws:s3:arn": [
            "${aws_s3_bucket.replica.arn}/*"
          ]
        }
      },
      "Resource": [
        "${data.aws_kms_alias.s3_replica.arn}"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "photos-bucket-replication-attachment"
  roles      = ["${aws_iam_role.replication.name}"]
  policy_arn = "${aws_iam_policy.replication.arn}"
}

resource "aws_s3_bucket" "replica" {
  provider      = "aws.replica"
  bucket        = "${data.aws_caller_identity.current.account_id}-photos-replica"
  acl           = "private"
  force_destroy = true
  region        = "${var.replica_region}"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "old_version_expiration"
    enabled = true

    noncurrent_version_expiration {
      days = "${var.bucket_retention}"
    }

    expiration {
      expired_object_delete_marker = true
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "${data.aws_kms_alias.s3_replica.arn}"
      }
    }
  }
}

resource "aws_s3_bucket" "backup" {
  bucket        = "${data.aws_caller_identity.current.account_id}-photos"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "old_version_expiration"
    enabled = true

    noncurrent_version_expiration {
      days = "${var.bucket_retention}"
    }

    expiration {
      expired_object_delete_marker = true
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  replication_configuration {
    role = "${aws_iam_role.replication.arn}"
    rules {
      id     = "replica"
      prefix = ""
      status = "Enabled"

      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }

      destination {
        bucket             = "${aws_s3_bucket.replica.arn}"
        replica_kms_key_id = "${data.aws_kms_alias.s3_replica.arn}"
      }
    }
  }
}

