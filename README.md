
# terraform-aws-billing-export

Terraform module to manage the setup of an automated billing data export pipeline from AWS Billing and Cost Management (BCM) to an S3 bucket.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.48 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.78.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bcmdataexports_export.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bcmdataexports_export) | resource |
| [aws_iam_policy.bcm_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.bcm_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.billing_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |

## Example

```terraform
module "bcmdataexports_export" {
  source  = "tfstack/billing-export/aws"

  account_id  = data.aws_caller_identity.current.account_id
  export_name = "bcm-report"

  iam_readonly_roles = [aws_iam_role.bcm_report_read_only.name]

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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID for the BCM export. This is used to identify the account associated with the export process. | `string` | n/a | yes |
| <a name="input_export_name"></a> [export\_name](#input\_export\_name) | The name of the BCM export. | `string` | n/a | yes |
| <a name="input_iam_readonly_roles"></a> [iam\_readonly\_roles](#input\_iam\_readonly\_roles) | List of IAM roles to attach the BCM export read-only policy | `list(string)` | `[]` | no |
| <a name="input_query_statement"></a> [query\_statement](#input\_query\_statement) | The SQL query for BCM data export. | `string` | `"    SELECT\n      identity_line_item_id,\n      identity_time_interval,\n      line_item_product_code,\n      line_item_unblended_cost\n    FROM COST_AND_USAGE_REPORT\n"` | no |
| <a name="input_refresh_frequency"></a> [refresh\_frequency](#input\_refresh\_frequency) | The refresh frequency for the BCM export. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region of the BCM. | `string` | `"ap-southeast-2"` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | A unique suffix used to create resources such as the S3 bucket name for BCM data export. | `string` | n/a | yes |
| <a name="input_s3_acl"></a> [s3\_acl](#input\_s3\_acl) | The ACL policy for the S3 bucket. | `string` | `"private"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the S3 bucket where the BCM data will be exported. | `string` | n/a | yes |
| <a name="input_s3_force_destroy"></a> [s3\_force\_destroy](#input\_s3\_force\_destroy) | If true, allows deleting a bucket even if it contains objects. | `bool` | `false` | no |
| <a name="input_s3_object_ownership"></a> [s3\_object\_ownership](#input\_s3\_object\_ownership) | The object ownership setting for the S3 bucket. Valid values: 'BucketOwnerPreferred', 'ObjectWriter', or 'BucketOwnerEnforced'. | `string` | `"BucketOwnerPreferred"` | no |
| <a name="input_s3_output_configurations"></a> [s3\_output\_configurations](#input\_s3\_output\_configurations) | Configuration for the output of S3 exports | <pre>object({<br/>    overwrite   = string<br/>    format      = string<br/>    compression = string<br/>    output_type = string<br/>  })</pre> | <pre>{<br/>  "compression": "GZIP",<br/>  "format": "TEXT_OR_CSV",<br/>  "output_type": "CUSTOM",<br/>  "overwrite": "OVERWRITE_REPORT"<br/>}</pre> | no |
| <a name="input_s3_sse_rule"></a> [s3\_sse\_rule](#input\_s3\_sse\_rule) | Server-side encryption rule for the S3 bucket. | <pre>object({<br/>    sse_algorithm     = string<br/>    kms_master_key_id = optional(string)<br/>  })</pre> | <pre>{<br/>  "sse_algorithm": "AES256"<br/>}</pre> | no |
| <a name="input_table_configurations"></a> [table\_configurations](#input\_table\_configurations) | The table configurations for the BCM data export. | <pre>map(object({<br/>    TIME_GRANULARITY                      = string<br/>    INCLUDE_RESOURCES                     = string<br/>    INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = string<br/>    INCLUDE_SPLIT_COST_ALLOCATION_DATA    = string<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. Tags are useful for identifying and managing resources in AWS. If no tags are provided, an empty map will be used. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bcm_export_id"></a> [bcm\_export\_id](#output\_bcm\_export\_id) | The ID of the BCM export. |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket used for BCM export. |
