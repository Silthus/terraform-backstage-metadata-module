resource "google_storage_bucket" "example" {
  name     = "example-bucket"
  location = "europe-west1"
  labels   = module.metadata.labels
}