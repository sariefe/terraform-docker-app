terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "lab" {
  name = "${var.project_name}-net"
}

resource "docker_volume" "db_data" {
  name = "${var.project_name}-db-data"
}

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_container" "db" {
  name  = "${var.project_name}-db"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name    = docker_network.lab.name
    aliases = ["db"]
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
    interval = "5s"
    timeout  = "3s"
    retries  = 10
  }

  wait    = true # healthy olana kadar bekler
  restart = "unless-stopped"
}
resource "docker_image" "app" {
  name = "${var.project_name}-app:latest"

  build {
    context = "${path.module}/app"
  }

  # app/ içindeki dosyalar değişince imaj yeniden derlenir
  triggers = {
    src_hash = sha1(join("", [
      for f in sort(fileset("${path.module}/app", "*")) :
      filesha1("${path.module}/app/${f}")
    ]))
  }
}

resource "docker_container" "app" {
  name  = "${var.project_name}-app"
  image = docker_image.app.image_id

  env = [
    "DB_HOST=db",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name    = docker_network.lab.name
    aliases = ["app"]
  }

  depends_on = [docker_container.db]
  restart    = "unless-stopped"
}
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "${var.project_name}-web"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }

  volumes {
    host_path      = abspath("${path.module}/nginx/default.conf")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.lab.name
  }

  depends_on = [docker_container.app]
  restart    = "unless-stopped"
}
