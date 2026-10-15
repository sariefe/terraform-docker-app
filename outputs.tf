output "url" {
  value = "http://localhost:${var.external_port}"
}

output "containers" {
  value = [
    module.web.name,
    module.app.name,
    module.db.name,
  ]
}
