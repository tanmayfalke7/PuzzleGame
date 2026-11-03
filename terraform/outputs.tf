output "instance_public_ip" {
  value       = aws_instance.puzzle_server.public_ip
  description = "Public IP address of the provisioned EC2 instance"
}

output "security_group_id" {
  value       = aws_security_group.puzzle_app_sg.id
  description = "ID of created security group"
}