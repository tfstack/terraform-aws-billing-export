terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.48"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# use of random suffix to avoid duplicate resource
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  lower   = true
  numeric = false
}

module "bcmdataexports_export" {
  source = "../.."

  account_id  = data.aws_caller_identity.current.account_id
  export_name = "bcm-report"

  query_statement = <<EOT
    SELECT
    identity_line_item_id,
    identity_time_interval,
    line_item_product_code,
    line_item_unblended_cost
    FROM COST_AND_USAGE_REPORT
  EOT

  refresh_frequency = "SYNCHRONOUS"
  region            = data.aws_region.current.name

  s3_acl              = "private"
  s3_bucket_name      = "bcm-export-${random_string.suffix.result}"
  s3_force_destroy    = true
  s3_object_ownership = "BucketOwnerPreferred"

  s3_output_configurations = {
    compression = "GZIP"
    format      = "TEXT_OR_CSV"
    output_type = "CUSTOM"
    overwrite   = "OVERWRITE_REPORT"
  }

  s3_sse_rule = {
    sse_algorithm = "AES256"
  }

  table_configurations = {
    COST_AND_USAGE_REPORT = {
      INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE"
      INCLUDE_RESOURCES                     = "FALSE"
      INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE"
      TIME_GRANULARITY                      = "HOURLY"
    }
  }
}
