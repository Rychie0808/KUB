provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

# RSA key of size 4096 bits
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

//Creating private key
resource "local_file" "keypair" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "key.pem"
  file_permission = "600"
}

//create my ec2 public key on aws
resource "aws_key_pair" "keypair" {
  key_name   = "kub-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}


//security group for docker
resource "aws_security_group" "kub-sg" {
  name        = "kub-sg"
  description = "instance_security_group"

  ingress {
    description = "Allow Imbound traffic"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "kub-sg"
  }
}

//creating Ec2 for master  
resource "aws_instance" "master" {
  ami                         = "ami-085f9c64a9b75eed5"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.keypair.id
  vpc_security_group_ids      = [aws_security_group.kub-sg.id]
  user_data                   = file("./test.sh")
  tags = {
    name = "master-node"
  }
}

//Creating Ec2 for worker 1
resource "aws_instance" "worker" {
  ami                         = "ami-085f9c64a9b75eed5"
  count                       = 2
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.keypair.id
  vpc_security_group_ids      = [aws_security_group.kub-sg.id]
  user_data                   = file("./worker-userdata.sh")
  tags = {
    name = "worker-node-${count.index}"
  }
}

output "master" {
  value = aws_instance.master.public_ip

}

output "worker" {
  value = aws_instance.worker.*.public_ip

}



