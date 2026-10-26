# Starting point: a resource called "old_name".
terraform {
  required_version = ">= 1.10"
}

resource "terraform_data" "old_name" {
  input = "same infrastructure, new name"
}
