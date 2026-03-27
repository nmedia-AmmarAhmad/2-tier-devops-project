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
              # 1. Update and install dependencies
              apt-get update -y
              # Install Node.js from nodesource to ensure we get a modern version (v18+)
              curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
              apt-get install -y mysql-client git nodejs
              npm install -g pm2

              # 2. Wait for RDS to be ready
              until mysql -h ${aws_db_instance.db.address} -u admin -p'ComplexPass123!' -e "SELECT 1;" &> /dev/null
              do
                echo "Waiting for RDS..."
                sleep 5
              done

              # 3. Code Deployment
              mkdir -p /home/ubuntu/app
              # IMPORTANT: Update the URL below to your actual repo
              git clone https://github.com/YOUR_USER/YOUR_REPO.git /home/ubuntu/app
              
              # Set permissions so 'ubuntu' user owns the files
              chown -R ubuntu:ubuntu /home/ubuntu/app
              cd /home/ubuntu/app

              # 4. Environment Setup
              # We create the .env file so the app knows where the DB is
              echo "DB_HOST=${aws_db_instance.db.address}" > .env
              echo "DB_USER=admin" >> .env
              echo "DB_PASSWORD=ComplexPass123!" >> .env
              echo "DB_NAME=ammar_db" >> .env

              # 5. Start the App as the 'ubuntu' user
              sudo -u ubuntu npm install
              sudo -u ubuntu pm2 start app.js --name "ammar-app"
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
