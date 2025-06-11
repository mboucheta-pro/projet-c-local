output "github_runner_ip" {
  description = "Adresse IP publique du runner GitHub"
  value       = aws_instance.github_runner.public_ip
}

output "private_key_pem" {
  description = "Clé privée SSH PEM pour le déploiement"
  value       = tls_private_key.deployer.private_key_pem
  sensitive   = true
}

output "public_key_openssh" {
  description = "Clé publique SSH au format OpenSSH"
  value       = tls_private_key.deployer.public_key_openssh
}
