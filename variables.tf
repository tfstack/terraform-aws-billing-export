variable "account_id" {
  description = "The AWS account ID for the BCM export. This is used to identify the account associated with the export process."
  type        = string
}

variable "export_name" {
  description = "The name of the BCM export."
  type        = string
}

variable "query_statement" {
  description = "The SQL query for BCM data export."
  type        = string
  default     = <<EOT
    SELECT
      identity_line_item_id,
      identity_time_interval,
      line_item_product_code,
      line_item_unblended_cost
    FROM COST_AND_USAGE_REPORT
  EOT
}

variable "refresh_frequency" {
  description = "The refresh frequency for the BCM export."
  type        = string

  validation {
    condition     = contains(["SYNCHRONOUS"], var.refresh_frequency)
    error_message = "The refresh frequency setting must be one of: 'SYNCHRONOUS'."
  }
}

variable "region" {
  description = "The AWS region of the BCM."
  type        = string
  default     = "ap-southeast-2"

  validation {
    condition = contains(
      [
        "us-east-1", "us-west-1", "us-west-2", "eu-west-1", "eu-central-1",
        "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "sa-east-1",
        "ca-central-1", "eu-west-2", "ap-south-1", "us-east-2", "us-west-3",
        "us-west-4", "eu-west-3", "eu-north-1", "ap-northeast-2", "ap-northeast-3",
        "af-south-1", "me-south-1", "ap-east-1", "eu-south-1", "eu-west-4",
        "ap-southeast-3", "sa-east-2"
      ],
      var.region
    )
    error_message = <<EOF
Invalid AWS region. Please choose from the following:

us-east-1, us-west-1, us-west-2, eu-west-1, eu-central-1,
ap-southeast-1, ap-southeast-2, ap-northeast-1, sa-east-1,
ca-central-1, eu-west-2, ap-south-1, us-east-2, us-west-3,
us-west-4, eu-west-3, eu-north-1, ap-northeast-2, ap-northeast-3,
af-south-1, me-south-1, ap-east-1, eu-south-1, eu-west-4,
ap-southeast-3, sa-east-2.

EOF
  }
}

variable "s3_acl" {
  description = "The ACL policy for the S3 bucket."
  type        = string
  default     = "private"

  validation {
    condition = contains([
      "private",
      "public-read",
      "public-read-write",
      "aws-exec-read",
      "authenticated-read",
      "bucket-owner-read",
      "bucket-owner-full-control",
      "log-delivery-write"
    ], var.s3_acl)
    error_message = <<EOM
    Invalid ACL policy. Valid values are:
    - 'private'
    - 'public-read'
    - 'public-read-write'
    - 'aws-exec-read'
    - 'authenticated-read'
    - 'bucket-owner-read'
    - 'bucket-owner-full-control'
    - 'log-delivery-write'
    EOM
  }
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket where the BCM data will be exported."
  type        = string
}

variable "s3_force_destroy" {
  description = "If true, allows deleting a bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "s3_object_ownership" {
  description = "The object ownership setting for the S3 bucket. Valid values: 'BucketOwnerPreferred', 'ObjectWriter', or 'BucketOwnerEnforced'."
  type        = string

  default = "BucketOwnerPreferred"

  validation {
    condition     = contains(["BucketOwnerPreferred", "ObjectWriter", "BucketOwnerEnforced"], var.s3_object_ownership)
    error_message = <<EOM
    The object ownership setting must be one of:
    - 'BucketOwnerPreferred'
    - 'ObjectWriter'
    - 'BucketOwnerEnforced'
    EOM
  }
}

variable "s3_output_configurations" {
  description = "Configuration for the output of S3 exports"
  type = object({
    overwrite   = string
    format      = string
    compression = string
    output_type = string
  })
  default = {
    overwrite   = "OVERWRITE_REPORT"
    format      = "TEXT_OR_CSV"
    compression = "GZIP"
    output_type = "CUSTOM"
  }

  validation {
    condition = alltrue([
      contains(["OVERWRITE_REPORT", "KEEP_EXISTING"], var.s3_output_configurations.overwrite),
      contains(["PARQUET", "TEXT_OR_CSV"], var.s3_output_configurations.format),
      contains(["GZIP", "PARQUET"], var.s3_output_configurations.compression),
      contains(["CUSTOM"], var.s3_output_configurations.output_type)
    ])
    error_message = <<EOM
    Invalid S3 output configuration:
    - 'overwrite' must be 'OVERWRITE_REPORT' or 'KEEP_EXISTING'.
    - 'format' must be 'TEXT_OR_CSV' or 'PARQUET'.
    - 'compression' must be 'GZIP' or 'NONE'.
    - 'output_type' must be 'CUSTOM' or 'DEFAULT'.
    EOM
  }
}

variable "s3_sse_rule" {
  description = "Server-side encryption rule for the S3 bucket."
  type = object({
    sse_algorithm     = string
    kms_master_key_id = optional(string)
  })
  default = {
    sse_algorithm = "AES256"
  }

  validation {
    condition     = contains(["AES256", "aws:kms", "aws:kms:dsse"], var.s3_sse_rule.sse_algorithm)
    error_message = <<EOM
    The sse_algorithm must be one of:
    - 'AES256'
    - 'aws:kms'
    - 'aws:kms:dsse'
    EOM
  }
}

variable "table_configurations" {
  description = "The table configurations for the BCM data export."
  type = map(object({
    TIME_GRANULARITY                      = string
    INCLUDE_RESOURCES                     = string
    INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = string
    INCLUDE_SPLIT_COST_ALLOCATION_DATA    = string
  }))
}

variable "tags" {
  description = "A map of tags to assign to the resources. Tags are useful for identifying and managing resources in AWS. If no tags are provided, an empty map will be used."
  type        = map(string)
  default     = {}
}
