terraform {
  backend "gcs" {
    bucket = "iac-devops-484714-tfstate"
    prefix = "environments/staging"
  }
}
