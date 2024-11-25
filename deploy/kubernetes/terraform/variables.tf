variable "aws_amis" {
  description = "The AMI to use for setting up the instances."
  default = {
    # Ubuntu 22.04 LTS
    "eu-west-3" = "ami-07db896e164bc4476"
  }
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-west-3"
}

variable "instance_user" {
  description = "The user account to use on the instances to run the scripts."
  default     = "ubuntu"
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "rt-deploy-docs-k8s"
}

variable "master_instance_type" {
  description = "The instance type to use for the Kubernetes master."
  default     = "t2.medium"
}

variable "node_instance_type" {
  description = "The instance type to use for the Kubernetes nodes."
  default     = "t2.large"
}

variable "master_count" {
  description = "The number of masters in the cluster."
  default     = "1"
}

variable "node_count" {
  description = "The number of nodes in the cluster."
  default     = "2"
}

variable "private_key_path" {
  description = "The private key for connection to the instances as the user. Corresponds to the key_name variable."
  default     = "~/.ssh/deploy-docs-k8s.pem"
}

variable "initial_configuration_commands" {
  default = [
      "sudo swapoff -a",
      "sudo apt-get update",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install docker.io -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "sudo mkdir -p /etc/containerd/",
      "containerd config default | sudo tee /etc/containerd/config.toml",
      "sudo sed -i 's/SystemdCgroup \\= false/SystemdCgroup \\= true/g' /etc/containerd/config.toml",
      "sudo systemctl restart containerd"
    ]
}