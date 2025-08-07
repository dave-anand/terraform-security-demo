output "vulnerable_bucket_name" {
  description = "Name of the vulnerable S3 bucket"
  value       = aws_s3_bucket.vulnerable_bucket.bucket
}

output "vulnerable_instance_id" {
  description = "ID of the vulnerable EC2 instance"
  value       = aws_instance.vulnerable_instance.id
}

output "security_group_id" {
  description = "ID of the vulnerable security group"
  value       = aws_security_group.vulnerable_sg.id
}