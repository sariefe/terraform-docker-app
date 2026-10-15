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

# ---------------------------------------------------------------
# Ağ ve volume
# ---------------------------------------------------------------
resource "docker_network" "lab" {
  name = "${var.project_name}-net"
}

resource "docker_volume" "db_data" {
  name = "${var.project_name}-db-data"
}

# ---------------------------------------------------------------
# İmajlar
# ---------------------------------------------------------------
resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
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

# ---------------------------------------------------------------
# Container'lar (modules/container)
# ---------------------------------------------------------------
module "db" {
  source = "./modules/container"

  name         = "${var.project_name}-db"
  image_id     = docker_image.postgres.image_id
  network_name = docker_network.lab.name
  aliases      = ["db"]
  wait         = true

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  volumes = [{
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }]

  healthcheck = {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
    interval = "5s"
    timeout  = "3s"
    retries  = 10
  }
}

module "app" {
  source = "./modules/container"

  name         = "${var.project_name}-app"
  image_id     = docker_image.app.image_id
  network_name = docker_network.lab.name
  aliases      = ["app"]

  env = [
    "DB_HOST=db",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
  ]

  depends_on = [module.db]
}

module "web" {
  source = "./modules/container"

  name         = "${var.project_name}-web"
  image_id     = docker_image.nginx.image_id
  network_name = docker_network.lab.name

  ports = [{
    internal = 80
    external = var.external_port
  }]

  volumes = [{
    host_path      = abspath("${path.module}/nginx/default.conf")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }]

  depends_on = [module.app]
}

# ---------------------------------------------------------------
# State taşıma: mevcut container'lar silinip yeniden oluşturulmaz.
# `terraform apply` başarıyla bittikten sonra bu bloklar silinebilir.
# ---------------------------------------------------------------
moved {
  from = docker_container.db
  to   = module.db.docker_container.this
}

moved {
  from = docker_container.app
  to   = module.app.docker_container.this
}

moved {
  from = docker_container.web
  to   = module.web.docker_container.this
}
