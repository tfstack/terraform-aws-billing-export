resource "aws_s3_bucket" "this" {
  bucket        = var.s3_bucket_name
  force_destroy = var.s3_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.s3_object_ownership
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = var.s3_acl

  depends_on = [
    aws_s3_bucket_ownership_controls.this
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_sse_rule.sse_algorithm
      kms_master_key_id = try(var.s3_sse_rule.kms_master_key_id, null)
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAWSDataExportsToWriteToS3AndCheckPolicy"
        Effect = "Allow"
        Principal = {
          Service = [
            "billingreports.amazonaws.com",
            "bcm-data-exports.amazonaws.com"
          ]
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketPolicy"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
        Condition = {
          StringLike = {
            "aws:SourceAccount" = var.account_id
            "aws:SourceArn" = [
              "arn:aws:cur:us-east-1:${var.account_id}:definition/*",         # this only works on us-east-1 region
              "arn:aws:bcm-data-exports:us-east-1:${var.account_id}:export/*" # this only works on us-east-1 region
            ]
          }
        }
      }
    ]
  })
}

resource "aws_bcmdataexports_export" "this" {
  export {
    name = var.export_name

    data_query {
      query_statement      = var.query_statement
      table_configurations = var.table_configurations
    }

    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.this.bucket
        s3_prefix = aws_s3_bucket.this.bucket_prefix
        s3_region = aws_s3_bucket.this.region

        s3_output_configurations {
          overwrite   = var.s3_output_configurations.overwrite
          format      = var.s3_output_configurations.format
          compression = var.s3_output_configurations.compression
          output_type = var.s3_output_configurations.output_type
        }
      }
    }

    refresh_cadence {
      frequency = var.refresh_frequency
    }
  }
}
