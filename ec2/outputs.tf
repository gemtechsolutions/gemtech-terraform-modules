output "public_ip" {
  description = "Public IP of the relay node"
  value       = aws_instance.relay_node.public_ip
} 

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.relay_node.id
} 

output "private_ip" {
  description = "Private IP of the relay node"
  value       = aws_instance.relay_node.private_ip
} 