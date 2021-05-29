output "ec2_instance_ip_address" {
  description = "The address of the EC2 instance"
  value       = aws_instance.WEBSERVER.public_ip
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.AWS-DB-MYSQL-1.address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.AWS-DB-MYSQL-1.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.AWS-DB-MYSQL-1.endpoint
}