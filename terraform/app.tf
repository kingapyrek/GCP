data "google_project" "project" {}

resource "google_artifact_registry_repository" "my-repo" {
  location      = var.region
  repository_id = "my-repository"
  description   = "example docker repository"
  format        = "DOCKER"
}

resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "cd .. ; chmod +x docker_script.sh; ./docker_script.sh ${var.config_json_path} ${var.region} ${var.project} ${google_artifact_registry_repository.my-repo.name}"
  }
}

resource "google_cloud_run_service" "default" {
  name     = "cloudrun-service"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/my-repository/app-image:tag1"
        # Sets a environment variable for instance connection name
        env {
          name  = "INSTANCE_UNIX_SOCKET"
          value = "/cloudsql/${var.project}:${var.region}:postgres-instance-app/"
        }
        # Sets a secret environment variables
        env {
          name = "DB_USER"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.dbuser.secret_id # secret name
              key  = "latest"                                      # secret version number or 'latest'
            }
          }
        }
        env {
          name = "DB_PASS"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.dbpass.secret_id # secret name
              key  = "latest"                                      # secret version number or 'latest'
            }
          }
        }
        env {
          name = "DB_NAME"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.dbname.secret_id # secret name
              key  = "latest"                                      # secret version number or 'latest'
            }
          }
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/client-name" = "terraform"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgres_app_db.connection_name
      }
    }
  }

  autogenerate_revision_name = true
  depends_on                 = [null_resource.example1, google_secret_manager_secret.dbuser, google_secret_manager_secret.dbpass, google_secret_manager_secret.dbname, google_project_service.secretmanager_api, google_project_service.cloudrun_api, google_project_service.sqladmin_api, google_secret_manager_secret_iam_member.secretaccess_compute_dbpass, google_secret_manager_secret_iam_member.secretaccess_compute_dbuser, google_secret_manager_secret_iam_member.secretaccess_compute_dbname]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}


resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.default.location
  service     = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}