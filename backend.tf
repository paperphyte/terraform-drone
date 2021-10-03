terraform {
  required_version = ">=0.14"

  backend "remote" {
    organization = "paperphyte"
    workspaces {
      name = "terraform-drone"
    }
  }
}
