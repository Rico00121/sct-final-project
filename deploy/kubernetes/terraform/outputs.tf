output "node_addresses" {
  value = aws_instance.sockshop-k8s-node.*.public_dns
}

output "master_address" {
  value = aws_instance.sockshop-k8s-master.*.public_dns
}


output "master_instance_type" {
  description = "The instance type for the master node"
  value       = var.master_instance_type
}

output "node_instance_type" {
  description = "The instance type for the worker nodes"
  value       = var.node_instance_type
}

output "aws_availability_zones" {
  value       = data.aws_availability_zones.available
}