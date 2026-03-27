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
              apt-get update -y
              apt-get install -y mysql-client git nodejs npm
              sudo npm install -g pm2

              # Wait for RDS
              until mysql -h ${aws_db_instance.db.address} -u admin -p'ComplexPass123!' -e "SELECT 1;" &> /dev/null
              do
                sleep 5
              done

              # Deploy Code
              mkdir -p /home/ubuntu/app
              git clone https://github.com/YOUR_USER/YOUR_REPO.git /home/ubuntu/app
              cd /home/ubuntu/app
              npm install

              # Start App
              echo "DB_HOST=${aws_db_instance.db.address}" > .env
              pm2 start app.js --name "ammar-app"
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
