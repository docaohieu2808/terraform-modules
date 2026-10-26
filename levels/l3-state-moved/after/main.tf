# Refactor: the resource is renamed. Without the moved block Terraform would plan to destroy
# "old_name" and create "new_name"; with it, state is updated in place and nothing changes.
terraform {
  required_version = ">= 1.10"
}

resource "terraform_data" "new_name" {
  input = "same infrastructure, new name"
}

moved {
  from = terraform_data.old_name
  to   = terraform_data.new_name
}
