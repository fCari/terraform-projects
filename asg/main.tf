#  Red (VPC por defecto) 
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#  AMI propia 
data "aws_ami" "nginx" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nginx-server-v1"]
  }
}

#  Security Group 
resource "aws_security_group" "nginx" {
  name   = "nginx-asg-sg" # nombre distinto para no chocar con "nginx-sg" si ya existe
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["190.12.34.56/32"] # pon aquí tu IP real
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#  Launch Template
resource "aws_launch_template" "nginx" {
  name          = "nginx-asg-launch-template" 
  image_id      = data.aws_ami.nginx.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.nginx.id]

  block_device_mappings {
    device_name = data.aws_ami.nginx.root_device_name
    ebs {
      volume_size = 10
      volume_type = "gp3"
    }
  }

  monitoring {
    enabled = true
  }
}

#  Auto Scaling Group 
resource "aws_autoscaling_group" "nginx" {
  name                = "nginx-asg"
  min_size            = 1
  desired_capacity    = 1
  max_size            = 3
  vpc_zone_identifier = slice(sort(data.aws_subnets.default.ids), 0, 2) # 2 subnets / 2 AZ

  health_check_type         = "EC2"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.nginx.id
    version = aws_launch_template.nginx.latest_version
  }

  tag {
    key                 = "Name"
    value               = "nginx-asg"
    propagate_at_launch = true
  }
}

#  Escalado por CPU 
resource "aws_autoscaling_policy" "cpu" {
  name                      = "cpu-target-tracking"
  autoscaling_group_name    = aws_autoscaling_group.nginx.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40
  }
}