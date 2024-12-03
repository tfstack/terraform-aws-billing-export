output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for BCM export."
  value       = aws_s3_bucket.this.arn
}

output "bcm_export_id" {
  description = "The ID of the BCM export."
  value       = aws_bcmdataexports_export.this.id
}
