variable "aws_amis" {
  description = "The AMI to use for setting up the instances."
  default = {
    # Ubuntu Xenial 16.04 LTS
    "eu-west-3" = "ami-045a8ab02aadf4f88"
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
  default     = "t2.large"
}

variable "node_instance_type" {
  description = "The instance type to use for the Kubernetes nodes."
  default     = "t2.medium"
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
