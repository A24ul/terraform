provider "aws" {
  region     = "ap-southeast-2"
}


# 1 Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main_vpc"
  }
}

# 2 Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main_internet_gw"
  }
}

# 3 Custom route Table

resource "aws_route_table" "main-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# 4 Create a Subnet

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "main_subnet"
  }
}


# 5 Associate subnet with Route Table

resource "aws_route_table_association" "main_route_table_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main-route-table.id
}

# 6 Create Security group to allow port 22,80,443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow inbound web traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "Security_grp"
  }
}
# 7 Create a n/w interface with an ip in the subnet (which is created in step 4)

resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.main_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}


# 8 Assign an elastic IP to the n/w int (which is created in setp 7)

resource "aws_eip" "lb" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# 9 Create Ubuntu server and install/enable apache2

resource "aws_instance" "web_server_instance" {
  ami               = "ami-0dd60a46ecc6eac16"
  instance_type     = "t3.micro"
  availability_zone = "ap-southeast-2a"
  key_name          = "key_pair"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_nic.id
  }
  tags = {
    Name = "My_first_EC2_with_terraform"
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your first web server > /var/www/html/index.html'
                EOF
}

#resource "aws_key_pair" "demo" {
#  key_name   = "terraform-demo-key"
#  public_key = file("D:\Terraform\Crash_Course_FCC\id_ed25519.pub")
#}

/*
resource "aws_instance" "my_first_instance" {
  ami           = "ami-0dd60a46ecc6eac16"
  instance_type = "t3.micro"
  #    key_name = aws_key_pair.demo.key_name
  tags = {
    Name = "My_first_EC2_with_terraform"
  }
}

resource "aws_vpc" "first_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Prod_vpc"
  }  
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Prod_subnet"
  }
}


resource "aws_instance" "my_second_instance" {
    ami     = "ami-0dd60a46ecc6eac16"
    instance_type = "t3.small"
   tags = {
      Name = "My_second_EC2_with_terraform"
    }
}
*/

