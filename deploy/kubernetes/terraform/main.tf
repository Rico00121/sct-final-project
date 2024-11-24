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
    inline = [
      "sudo swapoff -a",
      "sudo apt-get update",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install docker.io -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",
    ]
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
    inline = [
      "sudo swapoff -a",
      "sudo apt-get update",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install docker.io -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",
    ]
  }
}

resource "aws_lb" "k8s-control-plane-nlb" {
  name               = "rt-k8s-control-plane-nlb"
  internal           = false
  security_groups    = [aws_security_group.k8s-security-group.id]
  load_balancer_type = "network"
  subnets            = data.aws_subnets.available.ids

  enable_deletion_protection = false

  tags = {
    Name = "k8s-control-plane-nlb"
  }
}

resource "aws_lb_target_group" "k8s-control-plane-target-group" {
  name     = "rt-k8s-control-plane"
  port     = 6443
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    protocol           = "TCP"
    port               = "traffic-port"
    interval           = 30
    timeout            = 5
    healthy_threshold  = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "k8s-control-plane-target-group"
  }
}

resource "aws_lb_listener" "k8s-control-plane-listener" {
  load_balancer_arn = aws_lb.k8s-control-plane-nlb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s-control-plane-target-group.arn
  }
}

resource "aws_lb_target_group_attachment" "k8s-control-plane-target-group-attachment" {
  for_each = {
    for k, v in aws_instance.sockshop-k8s-master:
    k => v
  }
  target_group_arn = aws_lb_target_group.k8s-control-plane-target-group.arn
  target_id        = each.value.id
  port             = 6443
}
