provider "aws" { region = "us-east-1" }

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "demo" {
  ami               = data.aws_ssm_parameter.ami.value
  instance_type     = "t3.micro"
  availability_zone = "us-east-1a"
  tags              = { Name = "ebs-demo" }

#2,3 4
  user_data = <<-EOF
    #!/bin/bash
    while [ ! -e /dev/sdf ]; do sleep 2; done    
    DEV=$(readlink -f /dev/sdf)

    blkid $DEV || mkfs -t xfs $DEV
    mkdir -p /data
    
    echo "UUID=$(blkid -s UUID -o value $DEV) /data xfs defaults,nofail 0 2" >> /etc/fstab
    mount -a
    echo "prueba $(date)" > /data/prueba.txt
  EOF
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.demo.availability_zone
  size              = 10
  type              = "gp3"
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.demo.id
}

output "instance_id" { value = aws_instance.demo.id }