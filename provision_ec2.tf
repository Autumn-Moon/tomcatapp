#Set the Provider
provider "aws" {
  region = "ap-south-1"
}

#Create a New VPC
resource "aws_vpc" "acit_vpc" {
  cidr_block = "190.160.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  
  tags = {
      Name = "acit_vpc"
  }
}

#Create an Internet Gateway and attach to the New VPC
resource "aws_internet_gateway" "ACIT_IGW" {
  vpc_id = "${aws_vpc.acit_vpc.id}"
  tags = {
      Name = "ACIT_IGW"
  }
}

#Create a Route table and connect to Internet Gateway
resource "aws_route_table" "ACIT_ROUTE" {
  vpc_id = "${aws_vpc.acit_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ACIT_IGW.id}"
  }
  tags = {
      Name = "ACIT_PUBLIC_ROUTE"
  }
}

#Create a Network Access Control List and apply to VPC
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

    tags = {
        Name = "ACIT_NACL"
    }
}

#Create a Securtiy group inside the new VPC
resource "aws_security_group" "ACIT_SG" {
  vpc_id = "${aws_vpc.acit_vpc.id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
      Name = "ACIT_SG"
  }  
}

#Create a Subnet inside the newly created VPC in AZ ap-south-1a
resource "aws_subnet" "WebAppSubnet" {
  vpc_id = "${aws_vpc.acit_vpc.id}"
  cidr_block = "190.160.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
      Name = "WebAppSubnet"
  }
}

#Associate the route table to the newly created subnet and make it public subnet
resource "aws_route_table_association" "ACIT_RT_SNET" {
  subnet_id = "${aws_subnet.WebAppSubnet.id}"
  route_table_id = "${aws_route_table.ACIT_ROUTE.id}"
}

#Create a new Keypair to assign it to the EC2 instance
resource "aws_key_pair" "WiproKeyPair" {
  key_name   = "acit-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCG1ltK731bzWx/tDfzRjy5lNzBTx5UcGEVn32tdGH5sn3e86KEGPso0mh/E8lm6/2yC4pUWCFHIqD1Nr4MfaH3pysKlJcwgfVIz6ENB5ufcoexupRphtyzbqlhGrJSkqT7erTAoXJ335S/Fbc7TcII9HsS4HtnR/oCrFMQ5AufqEo96BfB3iNTTyO08hZEkTYYrPqa9MoeEc+WvsDKxUfxeSObA4j7c9xUNbAIj/SuI07URQ+h8ZBe6dfZNOn/ZYfl2XfW7Siuhueo9FeJP3d8CT+RVWxaspG+fTm12sJVRDowYk2v9BDZ6t1xqaXNNt7Ot4QbQNVFkM/b9lsCYArJ WiproKeyPair"

}

#Provision a t2.micro EC2 Instance
resource "aws_instance" "webapp" {
  instance_type = "t2.micro"
  ami = "${var.amiInstance}"
  subnet_id = "${aws_subnet.WebAppSubnet.id}"
  vpc_security_group_ids = ["${aws_security_group.ACIT_SG.id}"]
  associate_public_ip_address = true
  key_name = "${aws_key_pair.WiproKeyPair.id}"

  tags = {
      Name = "webappInstance"
  }
  
}
#Variable for the EC2 AMI
variable "amiInstance" {
  description = "AMI Amazon Linux AMI 2018.03.0"
  default = "ami-02913db388613c3e1"  
}
