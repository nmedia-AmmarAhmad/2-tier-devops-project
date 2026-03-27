resource "aws_launch_template" "app" {
  name_prefix   = "ammar-app-"
  image_id      = "ami-04a81a99f5ec58529" # Updated Ubuntu 24.04 ID for us-east-1
  instance_type = "t3.micro"
  key_name      = "ammar-key"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Install Node.js & MySQL Client
              apt-get update -y
              curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
              apt-get install -y mysql-client nodejs
              npm install -g pm2

              # 2. Setup the Database (Wait for RDS)
              until mysql -h ${aws_db_instance.db.address} -u admin -p'ComplexPass123!' -e "SELECT 1;" &> /dev/null
              do
                sleep 5
              done

              # 3. Create Table
              mysql -h ${aws_db_instance.db.address} -u admin -p'ComplexPass123!' -e "CREATE DATABASE IF NOT EXISTS ammar_db; USE ammar_db; CREATE TABLE IF NOT EXISTS tickets (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(255), issue TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
              
              # We stop here. GitHub will do the rest.
              EOF
  )
}




resource "aws_autoscaling_group" "app" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.tg.arn]
  vpc_zone_identifier = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
