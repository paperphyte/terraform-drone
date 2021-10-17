variable "dns_root_name" {
  type        = string
  description = "The root domain name such as example.com"
}

variable "dns_root_id" {
  type        = string
  description = "The root domain zone name"
}

variable "drone_admin" {
  type        = string
  description =  "A default user to be admin of drone at creation"
}

variable "drone_user_filter" {
  type        = string
  description = "Organisation or username to allow build from"
}

variable "allowed_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "A cidr to limit access to drone user interface"
}

variable "versions" {
  description = "Version of drone task container image"
  type        = object({
    server  = string
    secrets = string
    yaml    = string
    runner  = string
  })
  default     = {
    server  = "v2.4.0"
    secrets = "v1.0.0"
    yaml    = "v0.4.2"
    runner  = "v1.6.3"
  }
}
