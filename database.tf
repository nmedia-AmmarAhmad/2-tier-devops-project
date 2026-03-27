# 1. Database Subnet Group (Required for RDS to know which subnets to use)
resource "aws_db_subnet_group" "db_sub" {
  name       = "ammar-db-subgroup"
  subnet_ids = [aws_subnet.pub_1.id, aws_subnet.pub_2.id] # Using public for learning/access
}

# 2. Database Security Group (The "Vault Door")
resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.main.id

  # Allow MySQL traffic (3306) ONLY from the App Server's Security Group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. The Actual Database (This is the "aws_db_instance.db" your error mentioned)
resource "aws_db_instance" "db" {
  allocated_storage    = 10
  db_name              = "ammar_db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "ComplexPass123!"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = true # So you can check it from your PC if needed

  db_subnet_group_name   = aws_db_subnet_group.db_sub.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}
