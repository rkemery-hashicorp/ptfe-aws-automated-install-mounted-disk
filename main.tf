# Configure AWS Provider
provider "aws" {
  version    = "~> 2.0"
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create a Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.main]
}

# Create Security Group
resource "aws_security_group" "main" {
  name        = "ptfe-demo"
  description = "Allow SSH, ICMP, HTTPS, and PTFE"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_subnet.main]

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }

  ingress {
    from_port   = 8800
    to_port     = 8800
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = var.my_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow SSH, ICMP, HTTPS, and PTFE"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create route tables
resource "aws_route_table" "main" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_internet_gateway.main]

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Generate Key
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Key Pair
resource "aws_key_pair" "main" {
  key_name    = var.key_name
  public_key  = tls_private_key.main.public_key_openssh
}

# Create AWS Instance
resource "aws_instance" "main" {
  ami                         = "ami-0deae60d2ac515b3c"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.main.id
  key_name                    = aws_key_pair.main.key_name
  # associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.main.id]
  # private_ip                  = "10.0.1.100"

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo mkdir -p /opt/ptfe
    sudo mv /tmp/license.rli /etc/license.rli
    sudo mv /tmp/application-settings.json /etc/application-settings.json
    sudo mv /tmp/server.crt /etc/server.crt
    sudo mv /tmp/server.key /etc/server.key
    sudo mv /tmp/replicated.conf /etc/replicated.conf
    sudo chmod a+x /tmp/godaddy.sh
    sudo bash /tmp/godaddy.sh
    sudo rm -f /tmp/godaddy.sh
    cd /tmp
    curl -o install.sh https://install.terraform.io/ptfe/stable
    export PUBLICIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
    export PRIVATEIP="$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
    sudo bash ./install.sh private-address=$PRIVATEIP public-address=$PUBLICIP no-proxy no-docker=1
  EOF

  tags = {
    Name = "ptfe-demo"
  }
}

# Create Elastic IP
resource "aws_eip" "main" {
vpc                       = true
instance                  = aws_instance.main.id
depends_on                = [aws_internet_gateway.main]
}

resource "null_resource" upload_license {
depends_on = [aws_instance.main]

  provisioner "file" {
    source      = "./config/license.rli"
    destination = "/tmp/license.rli"
  }

  connection {
    host     = aws_eip.main.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    agent    = "false"
  }
}

resource "null_resource" upload_application_settings {
depends_on = [aws_instance.main]

  provisioner "file" {
    source      = "./config/application-settings.json"
    destination = "/tmp/application-settings.json"
  }

  connection {
    host     = aws_eip.main.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    agent    = "false"
  }
}

resource "null_resource" upload_replicated_conf {
depends_on = [aws_instance.main]

  provisioner "file" {
    source      = "./config/replicated.conf"
    destination = "/tmp/replicated.conf"
  }

  connection {
    host     = aws_eip.main.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    agent    = "false"
  }
}

resource "null_resource" upload_server_cert {
depends_on = [aws_instance.main]

  provisioner "file" {
    source      = "./certs/server.crt"
    destination = "/tmp/server.crt"
  }

  connection {
    host     = aws_eip.main.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    agent    = "false"
  }
}

resource "null_resource" upload_server_key {
depends_on = [aws_instance.main]

  provisioner "file" {
    source      = "./certs/server.key"
    destination = "/tmp/server.key"
  }

  connection {
    host     = aws_eip.main.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    agent    = "false"
  }
}

resource "null_resource" upload_godaddy_script {
depends_on = [aws_instance.main]

  provisioner "file" {
    source      = "./scripts/godaddy.sh"
    destination = "/tmp/godaddy.sh"
  }

  connection {
    host     = aws_eip.main.public_ip
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    agent    = "false"
  }
}

