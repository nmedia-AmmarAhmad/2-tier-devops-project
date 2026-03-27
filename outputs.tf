# The "Front Door" of your application
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

# The "Vault Address" for your database
output "rds_address" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.db.address
}

# The Name of the Database (needed for your App)
output "db_name" {
  value = aws_db_instance.db.db_name
}