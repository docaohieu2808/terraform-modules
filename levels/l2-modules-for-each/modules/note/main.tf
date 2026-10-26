# A tiny reusable module: one note file per call.
terraform {
  required_version = ">= 1.10"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

variable "name" {
  description = "Note name, used as the file name"
  type        = string
}

variable "lines" {
  description = "Lines of text in the note"
  type        = list(string)
  default     = []
}

variable "directory" {
  description = "Directory the note is written to"
  type        = string
}

resource "local_file" "note" {
  filename = "${var.directory}/${var.name}.txt"
  content  = templatefile("${path.module}/note.tftpl", { name = var.name, lines = var.lines })
}

output "path" {
  description = "Path of the written note"
  value       = local_file.note.filename
}

output "line_count" {
  description = "Number of lines written"
  value       = length(var.lines)
}
