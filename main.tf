provider "google" {
  project     = "mlops-project-397918"
  credentials = file("mlops-project-397918-93f61c353785.json")
  region      = "us-central1"
  zone        = "us-central1-c"
}
resource "google_storage_bucket" "my_bucket" {
  name          = "train-data-9923"           # Change to your desired bucket name
  location      = "US"                   # Change to your desired region
  force_destroy = true                   # Set to true to allow bucket deletion
}

resource "google_storage_bucket_object" "csv_upload" {
  name   = "train.csv"                  # Change to your desired object name
  bucket = google_storage_bucket.my_bucket.name
  source = "train.csv"       # Path to your local CSV file
  content_type = "text/csv"
}

resource "google_dataproc_cluster" "outlier_detection_cluster" {
  name          = "outlier-detection-cluster"
  project       = "mlops-project-397918"
  region        = "us-central1"
  cluster_config {
    master_config {
      num_instances = 1
      machine_type = "n1-standard-4"
    }
    worker_config {
      num_instances = 2
      machine_type = "n1-standard-4"
    }
    # Add any additional configuration options as needed
  }
}

# Create a Google Cloud Storage bucket
resource "google_storage_bucket" "my_bucket_2" {
  name     = "pyspark-script-9923"
  location = "US" # Change to your desired location
}

# Upload a local .py script to the GCS bucket
resource "google_storage_bucket_object" "python_script_upload" {
  name   = "script.py" # Change to your desired object name
  bucket = google_storage_bucket.my_bucket_2.name
  source = "outlier_detection.py" # Path to your local Python script
  content_type = "text/plain" # Change the content type if needed
}

resource "google_dataproc_job" "pyspark" {
  region       = google_dataproc_cluster.outlier_detection_cluster.region
  force_delete = true
  placement {
    cluster_name = google_dataproc_cluster.outlier_detection_cluster.name
  }

  pyspark_config {
    main_python_file_uri = "gs://pyspark-script-9923/script.py"
    properties = {
      "spark.logConf" = "true"
    }
  }
}



resource "google_bigquery_dataset" "example_dataset" {
  dataset_id = "dataset_9923"
  project    = "mlops-project-397918"
  labels = {
    environment = "development"
  }
}

resource "google_bigquery_table" "example_table" {
  dataset_id = google_bigquery_dataset.example_dataset.dataset_id
  project    = "mlops-project-397918"
  table_id   = "table_9923"

  schema = <<EOF
  [
    {
      "name": "column1",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "column2",
      "type": "INTEGER",
      "mode": "NULLABLE"
    }
  ]
  EOF

  labels = {
    environment = "development"
  }
}

