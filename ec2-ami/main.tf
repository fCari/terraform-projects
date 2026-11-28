terraform {
  required_providers {
    aws  = { source = "hashicorp/aws" }
    time = { source = "hashicorp/time" }
  }
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "base" {
  ami           = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
    echo "AWS EC2 - Custom AMI" | tee /usr/share/nginx/html/index.html
  EOF

  tags = { Name = "nginx-base" }
}

# Espera a que user_data termine de instalar Nginx
resource "time_sleep" "esperar_nginx" {
  depends_on      = [aws_instance.base]
  create_duration = "120s"
}

resource "aws_ami_from_instance" "nginx" {
  name               = "nginx-server-v1"
  source_instance_id = aws_instance.base.id

  depends_on = [time_sleep.esperar_nginx]
}

# Apaga
resource "aws_ec2_instance_state" "base" {
  instance_id = aws_instance.base.id
  state       = "stopped"

  depends_on = [aws_ami_from_instance.nginx]
}