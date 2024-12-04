terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.48"
    }
  }
}

# Generate a random suffix for resource naming
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  lower   = true
  numeric = false
}

resource "aws_iam_role" "bcm_report_read_only" {
  name = "bcm-report-read-only-${random_string.suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Output the AWS account ID for use in tests or external scripts
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Output the AWS region in use for verification or use in tests
output "region" {
  value = data.aws_region.current.name
}

# Output the generated random string suffix for resource naming
output "suffix" {
  value = random_string.suffix.result
}
