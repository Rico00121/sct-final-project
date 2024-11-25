provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "k8s-security-group" {
  name        = "rt-k8s-security-group"
  description = "Allow all internal traffic, SSH, HTTP from anywhere"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9411
    to_port     = 9411
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30002
    to_port     = 30002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
   from_port   = 31601
   to_port     = 31601
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sockshop-k8s-master" {
  instance_type = var.master_instance_type
  count = var.master_count
  ami           = lookup(var.aws_amis, var.aws_region)
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  tags = {
    Name = "sockshop-k8s-master"
  }

  connection {
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "../manifests"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = var.initial_configuration_commands
  }
}

resource "aws_instance" "sockshop-k8s-node" {
  instance_type = var.node_instance_type
  count         = var.node_count
  ami           = lookup(var.aws_amis, var.aws_region)
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  tags = {
    Name = "sockshop-k8s-node"
  }

  connection {
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = var.initial_configuration_commands
  }
}
