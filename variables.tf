variable "dns_root_name" {
  default = "paperphyte.com"
  type    = string
}

variable "dns_root_id" {
  default = ""
  type    = string
}

variable "versions" {
  type = object({
    server  = string
    secrets = string
    yaml    = string
    runner  = string
  })
  default = {
    server  = "v2.4.0"
    secrets = "v1.0.0"
    yaml    = "v0.4.2"
    runner  = "v1.6.3"
  }
}