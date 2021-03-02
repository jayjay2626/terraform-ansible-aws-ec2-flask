// defining a few local variables
locals {
    // copied from my aws account
    vpc_id                  = "vpc-f072c48a"
    subnet_id               = "subnet-acfa9df0"
    ssh_user                = "ubuntu"
    key_name                = "jayjay"
    private_key_path        = "jayjay.pem" // make sure .gitignore ignore this file and don't upload it to github
}

provider "aws" {
  region = "us-east-1"
}

// create custom security group
resource "aws_security_group" "flaskapp-sg" {
  name        = "flaskapp-sg"
  description = "Allow ssh http https jenkins inbound traffic"
  vpc_id = "local.vpc_id"

  // ssh port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // http port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // https port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // jenkins port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_instance" "flaskapp" {
  ami                     = "ami-03d315ad33b9d49c4"
  subnet_id               = local.subnet_id     //"subnet-acfa9df0"
  instance_type           = "t2.micro"
  key_name = local.key_name
  security_groups        = [aws_security_group.flaskapp-sg.id]

  provisioner "remote-exec" {
    inline = ["echo 'Waiting until Docker is ready"]

    connection {
        type            = "ssh"
        user            = local.ssh_user
        private_key     = file(local.private_key_path)
        host            = aws_instance.flaskapp.public_ip
    }
  }

  // local provisioner
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.flaskapp.public_ip}, --private-key ${local.private_key_path} docker.yaml"
  }

}


  output "flaskapp_public_ip" {
      value = aws_instance.flaskapp.public_ip
  }

