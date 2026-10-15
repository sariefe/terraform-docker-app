variable "name" {
  type = string
}

variable "image_id" {
  type = string
}

variable "network_name" {
  type = string
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "env" {
  type    = list(string)
  default = []
}

variable "ports" {
  type = list(object({
    internal = number
    external = number
  }))
  default = []
}

variable "volumes" {
  type = list(object({
    container_path = string
    volume_name    = optional(string)
    host_path      = optional(string)
    read_only      = optional(bool, false)
  }))
  default = []
}

variable "healthcheck" {
  type = object({
    test     = list(string)
    interval = string
    timeout  = string
    retries  = number
  })
  default = null
}

variable "wait" {
  type    = bool
  default = false
}

variable "restart" {
  type    = string
  default = "unless-stopped"
}
