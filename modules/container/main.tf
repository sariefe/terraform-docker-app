terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_container" "this" {
  name    = var.name
  image   = var.image_id
  env     = var.env
  wait    = var.wait
  restart = var.restart

  networks_advanced {
    name    = var.network_name
    aliases = var.aliases
  }

  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  dynamic "volumes" {
    for_each = var.volumes
    content {
      container_path = volumes.value.container_path
      volume_name    = volumes.value.volume_name
      host_path      = volumes.value.host_path
      read_only      = volumes.value.read_only
    }
  }

  dynamic "healthcheck" {
    for_each = var.healthcheck == null ? [] : [var.healthcheck]
    content {
      test     = healthcheck.value.test
      interval = healthcheck.value.interval
      timeout  = healthcheck.value.timeout
      retries  = healthcheck.value.retries
    }
  }
}
