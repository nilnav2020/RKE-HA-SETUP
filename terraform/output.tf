output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "control_plane_private_ips" {
  value = aws_instance.cp[*].private_ip
}

output "worker_private_ips" {
  value = aws_instance.worker[*].private_ip
}
