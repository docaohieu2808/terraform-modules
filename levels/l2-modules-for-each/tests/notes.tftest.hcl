run "one_file_per_note" {
  command = apply

  assert {
    condition     = length(output.paths) == 2 && alltrue([for p in values(output.paths) : fileexists(p)])
    error_message = "Each default note must be written"
  }

  assert {
    condition     = output.total_lines == 5
    error_message = "2 + 3 lines expected"
  }
}

run "adding_a_key_adds_an_instance" {
  command = apply

  variables {
    notes = { only = ["one line"] }
  }

  assert {
    condition     = keys(output.paths) == ["only"] && output.total_lines == 1
    error_message = "for_each should follow the map keys exactly"
  }

  assert {
    condition     = strcontains(file(output.paths["only"]), "- one line")
    error_message = "templatefile must render each line as a bullet"
  }
}
