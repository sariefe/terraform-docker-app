output "url" {
  value = "http://localhost:${var.external_port}"
}

output "containers" {
  value = [
    docker_container.web.name,
    docker_container.app.name,
    docker_container.db.name,
  ]
}
