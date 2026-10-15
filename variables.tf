variable "project_name" {
  type    = string
  default = "tflab"
}

variable "external_port" {
  type    = number
  default = 8080
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  sensitive = true # varsayılan yok, tfvars'tan gelecek
}

