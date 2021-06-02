# Markdown helper functions

from strutils import repeat, contains

# Add a line to given string
proc add_line*(str: var string; line: string) =
  str.add(line & '\n')

# Add some text
proc add_text*(md: var string; text: string) =
  md.add(text & '\n' & '\n')

# Add a markdown title
proc add_title*(md: var string; title: string; level: int) =
  assert(level >= 0)
  md.add_line(repeat('#', level + 1) & ' ' & title)

# Add a list
proc add_list_item*(md: var string; text: string; level: int) =
  assert(level >= 0)
  md.add_line(repeat("  ", level) & "- " & text)

# Add a code block
proc add_code*(md: var string; code, lang: string) =
  var fence = "```"
  # Sanitation
  while code.contains(fence):
    fence.add('`')
  md.add_line(fence & lang)
  md.add_line(code)
  md.add_line(fence)