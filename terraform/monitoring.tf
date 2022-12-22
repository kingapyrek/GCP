resource "google_monitoring_notification_channel" "basic" {
  display_name = "Test Notification Channel"
  type         = "email"
  labels = {
    email_address = "fake_email@blahblah.com"
  }
  force_delete = false
}

resource "google_monitoring_alert_policy" "db_cpu" {
  display_name = "Database CPU"
  combiner     = "OR"
  conditions {
    display_name = "test condition"
    condition_threshold {
        filter = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\""
        aggregations {
            alignment_period = "300s"
            cross_series_reducer = "REDUCE_NONE"
            per_series_aligner = "ALIGN_PERCENTILE_99"
        }
        comparison = "COMPARISON_GT"
        duration = "0s"
        trigger {
          count = 1
        }
        threshold_value = "0.8"
        
      }
    }
    notification_channels = [
        google_monitoring_notification_channel.basic.name
    ]
  }


resource "google_monitoring_alert_policy" "run_cpu" {
  display_name = "Cloud Run CPU container"
  combiner     = "OR"
  conditions {
    display_name = "test condition"
    condition_threshold {
        filter = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
        aggregations {
            alignment_period = "300s"
            cross_series_reducer = "REDUCE_NONE"
            per_series_aligner = "ALIGN_MEAN"
        }
        comparison = "COMPARISON_GT"
        duration = "0s"
        trigger {
          count = 1
        }
        threshold_value = "0.8"
        
      }
    }
        notification_channels = [
        google_monitoring_notification_channel.basic.name
    ]
  }