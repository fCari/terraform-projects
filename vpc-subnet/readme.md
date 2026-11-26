Arriba a la derecha selecciona la región N. Virginia (us-east-1). Si estás en otra región, no verás nada.
Busca el servicio VPC.
En Your VPCs busca lab-vpc.
En Subnets verás public-subnet y private-subnet.
En Route tables selecciona cada una y entra a la pestaña Routes:
la pública debe tener 0.0.0.0/0 → igw-...
la privada solo 10.20.0.0/16 → local
En Internet gateways verás el IGW asociado a la VPC.