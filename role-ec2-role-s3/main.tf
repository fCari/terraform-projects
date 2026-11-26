provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# S3
resource "aws_s3_bucket" "lab" {
  bucket        = "tecsup-class-${random_id.suffix.hex}"
  force_destroy = true
}

# Rol para EC2
resource "aws_iam_role" "ec2" {
  name = "ec2-s3-lab-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Política: get, put (subir/actualizar) y delete solo en este bucket
resource "aws_iam_role_policy" "s3_lab" {
  name = "s3-lab-bucket-access"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.lab.arn}/*"
      },
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.lab.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-s3-lab-access"
  role = aws_iam_role.ec2.name
}

# AMI Ubuntu 24.04 (se obtiene sola)
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# EC2
resource "aws_instance" "lab" {
  ami           = data.aws_ssm_parameter.ubuntu.value
  instance_type = "t3.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  tags = {
    Name = "ubuntu-server"
  }
}

# Subir archivo.txt al bucket
resource "aws_s3_object" "archivo" {
  bucket       = aws_s3_bucket.lab.id
  key          = "archivo.txt"
  source       = "${path.module}/archivo.txt"
  etag         = filemd5("${path.module}/archivo.txt")
  content_type = "text/plain"
}

output "bucket_name" {
  value = aws_s3_bucket.lab.id
}