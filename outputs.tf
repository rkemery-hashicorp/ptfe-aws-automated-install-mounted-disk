output "public_key_pem" {
  value = tls_private_key.main.public_key_pem
}

output "public_key_openssh" {
  value = tls_private_key.main.public_key_openssh
}

output "public_ip" {
  value = aws_eip.main.public_ip 
}
