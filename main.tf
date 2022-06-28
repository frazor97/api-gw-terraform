terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.25.0"
    }
  }
}

variable "gcp_region" {
  type        = string
  description = "Region to use for GCP provider"
  default     = "us-central1"
}

variable "gcp_project" {
  type        = string
  description = "Project to use for this config"
  default     = "aayush-terraform"
}

provider "google" {
  region  = var.gcp_region
  project = var.gcp_project
}

provider "google-beta" {
  region  = var.gcp_region
  project = var.gcp_project
}

resource "google_service_account" "api-sa" {
  account_id   = "api-sa"
  display_name = "Service Account"
}

resource "google_project_iam_member" "api-gateway-admin" {
  project = var.gcp_project
  role    = "roles/apigateway.admin"
  member  = "serviceAccount:${google_service_account.api-sa.email}"
}

resource "google_api_gateway_api" "api_gw" {
  project  = var.gcp_project
  provider = google-beta
  api_id   = "api-gw"
}

resource "google_api_gateway_api_config" "api_gw" {
  project       = var.gcp_project
  provider      = google-beta
  api           = google_api_gateway_api.api_gw.api_id
  api_config_id = "config"

  openapi_documents {
    document {
      path     = "openapi2-functions.yaml"
      contents = filebase64("openapi2-functions.yaml")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "api_gw" {
  project    = var.gcp_project
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_gw.id
  gateway_id = "api-gw"
}