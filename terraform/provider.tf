terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.45.0"
    }
  }
}

provider "google" {
  # Configuration options
  credentials = "${file(var.config_json_path)}"
  region = var.region
  project = var.project
}