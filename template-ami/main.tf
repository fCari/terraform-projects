data "aws_ami" "nginx" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nginx-server-v1"]
  }
}

resource "aws_security_group" "nginx" {
  name = "nginx-sg"

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
    cidr_blocks = ["190.12.34.56/32"] # pon aquí tu IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "nginx" {
  name          = "nginx-launch-template"
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