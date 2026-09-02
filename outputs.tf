output "instance_ids" {
  value = aws_instance.web[*].id
}

output "public_ips" {
  value = aws_instance.web[*].public_ip
}

output "public_dns" {
  value = aws_instance.web[*].public_dns
}

output "vpc_id" {
  value = aws_vpc.main.id
}