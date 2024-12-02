terraform {
  required_version = ">= 1.9.6, < 2"
  required_providers {
    backstage = {
      source  = "datolabs-io/backstage"
      version = ">= 3.1.0"
    }
  }
}
