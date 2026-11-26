1. EC2 + EBS en la misma AZ	Terraform (aws_instance y aws_ebs_volume)
2. Adjuntar e identificar el disco	Terraform adjunta. El script identifica el disco real con readlink -f /dev/sdf
3. Formatear, montar y archivo de prueba	user_data
4. fstab con UUID	user_data
5. Detener/iniciar y verificar	Manual