provider "aws" {
  access_key = "AKIAUMB5S4JWOZMZKZEW"
  secret_key = "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"
   region = "ap-south-1"
}

# Step1: Create a VPC

resource "aws_vpc" "ownvpc" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
        Name = "own-vpc"
    }
}

# Step2: Create Public subnet 

resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.ownvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "public-subnet"
    }
}

# Step2: Create Private subnet 

resource "aws_subnet" "private_subnet" {
    vpc_id     = aws_vpc.ownvpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"

    tags = {
        Name = "private-subnet"
    }
}

resource "aws_subnet" "private_subnet2" {
    vpc_id     = aws_vpc.ownvpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-1c"

    tags = {
        Name = "private-subnet2"
    }
}

# Step4: Create a igw

resource "aws_internet_gateway" "owngw" {
    vpc_id = aws_vpc.ownvpc.id

    tags = {
        Name = "own-igw"
    }
}

# Step5: Create public Route table

resource "aws_route_table" "public_table" {
    vpc_id = aws_vpc.ownvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.owngw.id
    }
    tags = {
        Name = "public-rt"
    }
}

# Step6: Create private Route table

resource "aws_route_table" "private_table" {
    vpc_id = aws_vpc.ownvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.owngw.id
    }
    tags = {
        Name = "private-rt"
    }
}

# Associate public route table 

resource "aws_route_table_association" "rta_subnet_public" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_table.id
}

# Associate private route table

resource "aws_route_table_association" "rta_subnet_private" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_table.id
}
resource "aws_route_table_association" "rta_subnet_private2" {
    subnet_id      = aws_subnet.private_subnet2.id
    route_table_id = aws_route_table.private_table.id
}

# Step7: Create Security Groups

resource "aws_security_group" "mywebsecurity" {
    name        = "my_web_security"
    description = "Allow http,ssh"
    vpc_id      = aws_vpc.ownvpc.id

    ingress {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        description      = "SSH"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    tags = {
        Name = "mywebserver_sg"
    }
}

# Step8: Creating a instance

resource "aws_instance" "webserver" {
    ami  =  "ami-0f5ee92e2d63afc18"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    associate_public_ip_address = true
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.mywebsecurity.id]
    key_name = "nihar"

    tags = {
        Name = "webserver"
    }
}

# Step9: Creating security groupfor rds.

resource "aws_security_group" "tutorial_db_sg" {
    name        = "tutorial_db_sg"
    description = "Security group for tutorial databases"
    vpc_id      = aws_vpc.ownvpc.id
    ingress {
        description     = "Allow MySQL traffic from only the web sg"
        from_port       = "3306"
        to_port         = "3306"
        protocol        = "tcp"
        security_groups = [aws_security_group.mywebsecurity.id]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "tutorial_db_sg"
    }
}

# Step 10: Creating aws_db_subnet_group.
resource "aws_db_subnet_group" "tutorial_db_subnet_group" {
    name        = "tutorial_db_subnet_group"
    description = "DB subnet group for tutorial"
    subnet_ids  = [aws_subnet.private_subnet.id,aws_subnet.private_subnet2.id]
}

#
resource "aws_db_instance" "default" {
    allocated_storage = 10
    engine                 = "mysql"
    engine_version         = "5.7"
    instance_class         = "db.t2.micro"
    db_name                = "tutorial"
    username               = "nihitdasi"
    password               = "nihar.2001"
    parameter_group_name   = "default.mysql5.7"
    db_subnet_group_name   = aws_db_subnet_group.tutorial_db_subnet_group.id
    vpc_security_group_ids = [aws_security_group.tutorial_db_sg.id]
    skip_final_snapshot    = true
}
