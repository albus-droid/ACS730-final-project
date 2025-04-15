output "instance_ids" {
  description = "IDs of the created EC2 instances."
  value       = { for instance in aws_instance.this : instance.name => instance.id }
}


output "public_ips" {
  description = "Public IP addresses of the EC2 instances (if associated)."
  value       = { for key, inst in aws_instance.this : key => inst.public_ip }
}
