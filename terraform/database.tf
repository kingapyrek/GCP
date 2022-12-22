resource "google_sql_database_instance" "postgres_app_db" {
  name             = "postgres-instance-app"
  region           = var.region
  database_version = "POSTGRES_14"
  root_password    = "abcABC123!"
  project          = var.project
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = false # set to true to prevent destruction of the resource
}

resource "google_sql_user" "users" {
  name     = "test-user"
  instance = google_sql_database_instance.postgres_app_db.name
  password = "password123"
  project  = var.project
}

# Create dbuser secret
resource "google_secret_manager_secret" "dbuser" {
  secret_id = "dbusersecret"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.secretmanager_api]
  project    = var.project
}

# Attaches secret data for dbuser secret
resource "google_secret_manager_secret_version" "dbuser_data" {
  secret      = google_secret_manager_secret.dbuser.id
  secret_data = google_sql_user.users.name
}

# Update service account for dbuser secret
resource "google_secret_manager_secret_iam_member" "secretaccess_compute_dbuser" {
  secret_id = google_secret_manager_secret.dbuser.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}


# Create dbpass secret
resource "google_secret_manager_secret" "dbpass" {
  secret_id = "dbpasssecret"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.secretmanager_api]
  project    = var.project
}

# Attaches secret data for dbpass secret
resource "google_secret_manager_secret_version" "dbpass_data" {
  secret      = google_secret_manager_secret.dbpass.id
  secret_data = google_sql_user.users.password
}

# Update service account for dbpass secret
resource "google_secret_manager_secret_iam_member" "secretaccess_compute_dbpass" {
  secret_id = google_secret_manager_secret.dbpass.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}


# Create dbname secret
resource "google_secret_manager_secret" "dbname" {
  secret_id = "dbnamesecret"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.secretmanager_api]
  project    = var.project
}

# Attaches secret data for dbname secret
resource "google_secret_manager_secret_version" "dbname_data" {
  secret      = google_secret_manager_secret.dbname.id
  secret_data = "postgres"
}

# Update service account for dbname secret
resource "google_secret_manager_secret_iam_member" "secretaccess_compute_dbname" {
  secret_id = google_secret_manager_secret.dbname.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}