provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "ACIT_VPC" {
  cidr_block = "190.160.0.0/16"
  instance_tenancy = "default"
  tags {
      Name = "acit_vpc"
  }
}

resource "aws_internet_gateway" "ACIT_IGW" {
  vpc_id = "${aws_vpc.acit_vpc.id}"
  tags {
      Name = "ACIT_IGW"
  }
}

resource "aws_route_table" "ACIT_ROUTE" {
  vpc_id = "${aws_vpc.acit_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ACIT_IGW}.id"
  }
  tags {
      Name = "ACIT_PUBLIC_ROUTE"
  }
}

resource "aws_network_acl" "ACIT_NACL" {
    vpc_id = "${aws_vpc.acit_vpc.id}"

    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 22
        to_port    = 22
    }

    subnet_id = "${aws_subnet.WebAppSubnet}"

    tags = {
        Name = "ACIT_NACL"
    }
}

resource "aws_security_group" "ACIT_SG" {
  vpc_id = "${aws_vpc.acit_vpc.id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = "0.0.0.0/0"
  }

  tags {
      Name = "ACIT_SG"
  }  
}

resource "aws_subnet" "WebAppSubnet" {
  vpc_id = "${aws_vpc.acit_vpc.id}"
  cidr_block = "190.160.1.0/24"
  availability_zone = "ap-south-1a"
  tags {
      Name = "WebAppSubnet"
  }
}

resource "aws_route_table_association" "ACIT_RT_SNET" {
  subnet_id = "${aws_subnet.WebAppSubnet}"
  route_table_id = "${aws_route_table.ACIT_ROUTE}"
}

resource "aws_instance" "webapp" {
  instance_type = "t2.micro"
  ami = "${var.amiInstance}"
  subnet_id = "${aws_subnet.WebAppSubnet}"
  security_groups = "${aws_security_group.ACIT_SG}"
  associate_public_ip_address = true

  tags {
      Name = "webappInstance"
  }
  
}

variable "amiInstance" {
  description = "AMI Amazon Linux AMI 2018.03.0"
  default = "ami-035b3c7efe6d061d5"  
}
