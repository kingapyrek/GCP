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
  credentials = "${file("/Users/kingapyrek/Downloads/complete-treat-371210-01eff99b8bdb.json")}"
  region = var.region
  project = var.project
}