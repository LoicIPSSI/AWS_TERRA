provider "aws" {
        region = "us-east-1"
}

#Création VPC
resource "aws_vpc" "TP-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "TP-VPC"
        }
}


### Création des subnets ###

# Subnet Public
resource "aws_subnet" "TP-SUBNET-PUBLIC" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "TP-SUBNET-PUBLIC"
        }
}

# Subnet AZ-A
resource "aws_subnet" "TP-SUBNET-AZ-A" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        cidr_block = "10.0.2.0/24"
        availability_zone = "us-east-1a"
        tags = {
                Name = "TP-SUBNET-AZ-A"
        }
}

# Subnet AZ-B
resource "aws_subnet" "TP-SUBNET-AZ-B" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        cidr_block = "10.0.3.0/24"
        availability_zone = "us-east-1b"
        tags = {
                Name = "TP-SUBNET-AZ-B"
        }
}

# Subnet AZ-C
resource "aws_subnet" "TP-SUBNET-AZ-C" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        cidr_block = "10.0.4.0/24"
        availability_zone = "us-east-1c"
        tags = {
                Name = "TP-SUBNET-AZ-C"
        }
}
 # Création de l'internet gateway AWS
resource "aws_internet_gateway" "TP-IGW" {
        tags = {
                Name = "TP-IGW"
        }
}

# Attache de la l'internet gateway au VPC 
resource "aws_internet_gateway_attachment" "TP-IGW-ATTACH" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.TP-IGW.id}"
}

# Création de la table de routable pour le réseau public
resource "aws_route_table" "TP-RTB-PUBLIC" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = "${aws_internet_gateway.TP-IGW.id}"
        }
        tags = {
                Name = "TP-RTB-PUBLIC"
        }
}

# Création d'une adresse elastique
resource "aws_eip" "TP-EIP" {
}


# Association de la table de routage au subnet public
resource "aws_route_table_association" "TP-RTB-PUBLIC-ASSOC" {
        subnet_id = "${aws_subnet.TP-SUBNET-PUBLIC.id}"
        route_table_id = "${aws_route_table.TP-RTB-PUBLIC.id}"
}

# Création du GRP-SECU PUBLIC-ADMIN
resource "aws_security_group" "TP-SG-PUBLIC-ADMIN" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        
        ### Règles entrantes
        # --> SSH
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"] #Mettre ip PUB de l'ipssi
        }
        ### Règles sortantes
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "TP-SG-PUBLIC-ADMIN"
        }
}


# Création du GRP-SECU PUBLIC-PROXY
resource "aws_security_group" "TP-SG-PUBLIC-PROXY" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        
        ### Règles entrantes
        # --> SSH
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                security_groups = ["${aws_security_group.TP-SG-PUBLIC-ADMIN.id}"]
        }
        # --> HTTP
        ingress {
                from_port = "80"
                to_port = "80"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }

        ### Règles sortantes
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "TP-SG-PUBLIC-PROXY"
        }
}

# Création du GRP-SECU PUBLIC-RPROXY
resource "aws_security_group" "TP-SG-PUBLIC-RPROXY" {
        vpc_id = "${aws_vpc.TP-VPC.id}"
        
        ### Règles entrantes
        # --> SSH
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                security_groups = ["${aws_security_group.TP-SG-PUBLIC-ADMIN.id}"]
        }
        # --> HTTP
        ingress {
                from_port = "80"
                to_port = "80"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }

        ### Règles sortantes
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "TP-SG-PUBLIC-RPROXY"
        }
}

# Création du GRP-SECU PRIVE
resource "aws_security_group" "TP-SG-PRIVE" {
        vpc_id = "${aws_vpc.TP-VPC.id}"

        ### Règles entrantes
        # --> SSH
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                security_groups = ["${aws_security_group.TP-SG-PUBLIC-ADMIN.id}"]
        }
        # --> HTTP
        ingress {
                from_port = "80"
                to_port = "80"
                protocol = "tcp"
                security_groups = ["${aws_security_group.TP-SG-PUBLIC-PROXY.id}"]
        }
        ### Règles sortantes
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "TP-SG-PRIVE"
        }
}

### Création des instances

# INSTANCE ADMIN
resource "aws_instance" "TP-INSTANCE-ADMIN" {
        subnet_id = "${aws_subnet.TP-SUBNET-PUBLIC.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.TP-SG-PUBLIC-ADMIN.id}"]
        associate_public_ip_address = true
        tags = {
                Name = "TP-INSTANCE-ADMIN"
        }
}

# INSTANCE RPROXY
resource "aws_instance" "TP-INSTANCE-RPROXY" {
        subnet_id = "${aws_subnet.TP-SUBNET-PUBLIC.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.TP-SG-PUBLIC-RPROXY.id}"]
        associate_public_ip_address = true
        tags = {
                Name = "TP-INSTANCE-RPROXY"
        }
        user_data = "${templatefile("rproxy.tpl", { WEB_IP1 = "${aws_instance.TP-INSTANCE-AZ-A.private_ip}", WEB_IP2 = "${aws_instance.TP-INSTANCE-AZ-B.private_ip}",WEB_IP3 = "${aws_instance.TP-INSTANCE-AZ-C.private_ip}"})}"
}

# INSTANCE PROXY
resource "aws_instance" "TP-INSTANCE-PROXY" {
        subnet_id = "${aws_subnet.TP-SUBNET-PUBLIC.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.TP-SG-PUBLIC-PROXY.id}"]
        associate_public_ip_address = true
        tags = {
                Name = "TP-INSTANCE-PROXY"
        }
	user_data = file("squid.tpl")
}

# INSTANCE WEB-AZ-A
resource "aws_instance" "TP-INSTANCE-AZ-A" {
        subnet_id = "${aws_subnet.TP-SUBNET-AZ-A.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.TP-SG-PRIVE.id}"]
        associate_public_ip_address = false
        tags = {
                Name = "TP-INSTANCE-AZ-A"
        }
	user_data = "${templatefile("web.tpl", { SQUID_IP = "${aws_instance.TP-INSTANCE-PROXY.private_ip}" })}"
}

# INSTANCE WEB-AZ-B
resource "aws_instance" "TP-INSTANCE-AZ-B" {
        subnet_id = "${aws_subnet.TP-SUBNET-AZ-B.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.TP-SG-PRIVE.id}"]
        associate_public_ip_address = false
        tags = {
                Name = "TP-INSTANCE-AZ-B"
        }
	user_data = "${templatefile("web.tpl", { SQUID_IP = "${aws_instance.TP-INSTANCE-PROXY.private_ip}" })}"
}

# INSTANCE WEB-AZ-C
resource "aws_instance" "TP-INSTANCE-AZ-C" {
        subnet_id = "${aws_subnet.TP-SUBNET-AZ-C.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.TP-SG-PRIVE.id}"]
        associate_public_ip_address = false
        tags = {
                Name = "TP-INSTANCE-AZ-C"
        }
	user_data = "${templatefile("web.tpl", { SQUID_IP = "${aws_instance.TP-INSTANCE-PROXY.private_ip}" })}"
}
