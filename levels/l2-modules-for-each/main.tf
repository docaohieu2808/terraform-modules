# Level 2: modules, for_each, templatefile, collection outputs - still local only.
terraform {
  required_version = ">= 1.10"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

variable "notes" {
  description = "Map of note name to its lines"
  type        = map(list(string))
  default = {
    shopping = ["milk", "rice"]
    todo     = ["learn terraform", "write a module", "add a test"]
  }
}

# One module instance per map entry. Adding or removing a key only touches that instance,
# which is why for_each is preferred over count for named things.
module "note" {
  source   = "./modules/note"
  for_each = var.notes

  name      = each.key
  lines     = each.value
  directory = "${path.module}/out"
}

output "paths" {
  description = "note name => file path"
  value       = { for name, m in module.note : name => m.path }
}

output "total_lines" {
  description = "Lines across all notes"
  value       = sum([for m in module.note : m.line_count])
}
