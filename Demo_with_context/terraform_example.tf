resource "google_storage_bucket" "test_bucket" {
    name = "test-bucket"
    location = "us-west2"
    storage_class = "STANDARD"
    project = "data-project"
}