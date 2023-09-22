terraform {
        required_providers {
                aws = {
                        source  = "hashicorp/aws"
                }
        }
}
provider "aws" {
        region = "us-east-1"
}
resource "aws_vpc" "LOIC-VPC" {
        cidr_block = "10.0.0.0/16"
        tags = {
                Name = "LOIC-VPC"
        }
}
resource "aws_subnet" "LOIC-SUBNET-PUBLIC" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        cidr_block = "10.0.1.0/24"
        tags = {
                Name = "LOIC-SUBNET-PUBLIC"
        }
}
resource "aws_subnet" "LOIC-SUBNET-PRIVATE" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        cidr_block = "10.0.2.0/24"
        tags = {
                Name = "LOIC-SUBNET-PRIVATE"
        }
}
resource "aws_internet_gateway" "LOIC-IGW" {
        tags = {
                Name = "LOIC-IGW"
        }
}
resource "aws_internet_gateway_attachment" "LOIC-IGW-ATTACH" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        internet_gateway_id = "${aws_internet_gateway.LOIC-IGW.id}"
}
resource "aws_route_table" "LOIC-RTB-PUBLIC" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = "${aws_internet_gateway.LOIC-IGW.id}"
        }
        tags = {
                Name = "LOIC-RTB-PUBLIC"
        }
}
resource "aws_eip" "LOIC-EIP" {
}
resource "aws_nat_gateway" "LOIC-NATGW" {
        subnet_id = "${aws_subnet.LOIC-SUBNET-PUBLIC.id}"
        allocation_id = "${aws_eip.LOIC-EIP.id}"
        tags = {
                Name = "LOIC-NATGW"
        }
}
resource "aws_route_table" "LOIC-RTB-PRIVATE" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        route {
                cidr_block = "0.0.0.0/0"
                nat_gateway_id = "${aws_nat_gateway.LOIC-NATGW.id}"
        }
        tags = {
                Name = "LOIC.RTB-PRIVATE"
        }
}
resource "aws_route_table_association" "LOIC-RTB-PRIVATE-ASSOC" {
        subnet_id = "${aws_subnet.LOIC-SUBNET-PRIVATE.id}"
        route_table_id = "${aws_route_table.LOIC-RTB-PRIVATE.id}"
}
resource "aws_route_table_association" "LOIC-RTB-PUBLIC-ASSOC" {
        subnet_id = "${aws_subnet.LOIC-SUBNET-PUBLIC.id}"
        route_table_id = "${aws_route_table.LOIC-RTB-PUBLIC.id}"
}
resource "aws_security_group" "LOIC-SG-PUBLIC" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
	ingress {
                from_port = "80"
                to_port = "80"
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "LOIC-SG-PUBLIC"
        }
}
resource "aws_security_group" "LOIC-SG-PRIVATE" {
        vpc_id = "${aws_vpc.LOIC-VPC.id}"
        ingress {
                from_port = "22"
                to_port = "22"
                protocol = "tcp"
                security_groups = ["${aws_security_group.LOIC-SG-PUBLIC.id}"]
        }
        egress {
                from_port = "0"
                to_port = "0"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
                Name = "LOIC-SG-PUBLIC"
        }
}
resource "aws_instance" "LOIC-INSTANCE-PUBLIC" {
        subnet_id = "${aws_subnet.LOIC-SUBNET-PUBLIC.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.LOIC-SG-PUBLIC.id}"]
        associate_public_ip_address = true
        tags = {
                Name = "LOIC-INSTANCE-PUBLIC"
        }
}
resource "aws_instance" "LOIC-INSTANCE-PRIVATE" {
        subnet_id = "${aws_subnet.LOIC-SUBNET-PRIVATE.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "loic"
        vpc_security_group_ids = ["${aws_security_group.LOIC-SG-PRIVATE.id}"]
        associate_public_ip_address = false
        tags = {
                Name = "LOIC-INSTANCE-PRIVATE"
        }
}
