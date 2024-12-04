# Initial setup to configure required inputs
run "setup" {
  module {
    source = "./tests/setup"
  }
}

# Test case: Create a BCM billing export resource
run "create_billing_export" {
  variables {
    # Inputs required for creating the billing export
    account_id  = run.setup.account_id
    export_name = "bcm-report"

    iam_readonly_roles = [
      "bcm-report-read-only-${run.setup.suffix}"
    ]

    query_statement = <<EOT
      SELECT
      identity_line_item_id,
      identity_time_interval,
      line_item_product_code,
      line_item_unblended_cost
      FROM COST_AND_USAGE_REPORT
    EOT

    refresh_frequency = "SYNCHRONOUS"
    region            = run.setup.region
    resource_suffix   = run.setup.suffix

    # S3 bucket configuration
    s3_acl              = "private"
    s3_bucket_name      = "bcm-export"
    s3_force_destroy    = true
    s3_object_ownership = "BucketOwnerPreferred"

    # S3 output configurations
    s3_output_configurations = {
      compression = "GZIP"
      format      = "TEXT_OR_CSV"
      output_type = "CUSTOM"
      overwrite   = "OVERWRITE_REPORT"
    }

    # S3 encryption configuration
    s3_sse_rule = {
      sse_algorithm = "AES256"
    }

    # Table configurations for the export
    table_configurations = {
      COST_AND_USAGE_REPORT = {
        INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE"
        INCLUDE_RESOURCES                     = "FALSE"
        INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE"
        TIME_GRANULARITY                      = "HOURLY"
      }
    }
  }

  # Assertions to validate the resources created

  # Validate S3 bucket name
  assert {
    condition     = aws_s3_bucket.this.bucket == "${var.s3_bucket_name}-${run.setup.suffix}"
    error_message = "Expected S3 bucket name to be '${var.s3_bucket_name}-${run.setup.suffix}', but it differs."
  }

  # Validate S3 bucket force_destroy attribute
  assert {
    condition     = aws_s3_bucket.this.force_destroy == var.s3_force_destroy
    error_message = "Expected S3 bucket 'force_destroy' to be '${var.s3_force_destroy}', but it differs."
  }

  # Validate S3 bucket ACL
  assert {
    condition     = aws_s3_bucket_acl.this.acl == var.s3_acl
    error_message = "Expected S3 bucket ACL to be '${var.s3_acl}', but it differs."
  }

  # Validate S3 bucket ownership controls
  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == var.s3_object_ownership
    error_message = "Expected S3 bucket object ownership to be '${var.s3_object_ownership}', but it differs."
  }

  # Validate S3 server-side encryption algorithm
  assert {
    condition = length([
      for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule :
      rule.apply_server_side_encryption_by_default[0].sse_algorithm
      if rule.apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    ]) > 0
    error_message = "Expected SSE algorithm to be 'AES256', but it differs."
  }

  # Validate KMS master key ID is not set (should be empty)
  assert {
    condition = length([
      for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule :
      rule.apply_server_side_encryption_by_default[0].kms_master_key_id
      if rule.apply_server_side_encryption_by_default[0].kms_master_key_id == ""
    ]) > 0
    error_message = "Expected KMS master key ID to be empty, but it is not."
  }

  # Validate export resource name
  assert {
    condition     = aws_bcmdataexports_export.this.export[0].name == "${var.export_name}-${run.setup.suffix}"
    error_message = "Expected export name to be '${var.export_name}-${run.setup.suffix}', but it differs."
  }

  # Validate query statement
  assert {
    condition     = aws_bcmdataexports_export.this.export[0].data_query[0].query_statement == var.query_statement
    error_message = "Expected query statement to match '${var.query_statement}', but it differs."
  }

  # Validate table configurations match the provided configurations
  assert {
    condition = length([
      for table_name, table_config in aws_bcmdataexports_export.this.export[0].data_query[0].table_configurations :
      table_config == var.table_configurations[table_name]
    ]) == length(var.table_configurations)
    error_message = "Expected table configurations to match the provided values, but they differ."
  }

  # Validate refresh frequency
  assert {
    condition     = aws_bcmdataexports_export.this.export[0].refresh_cadence[0].frequency == var.refresh_frequency
    error_message = "Expected refresh frequency to be '${var.refresh_frequency}', but it differs."
  }
}
