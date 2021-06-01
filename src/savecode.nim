## savecode

import os
import osproc
import markdown

# Prompts the user and returns the response
proc ask(msg: string): string =
  stdout.write(msg)
  return readLine(stdin)

# Get the git repo
var root = ask("Path to git repo: ")
# Ensure its a valid directory
while not dirExists(root):
  root = ask("invalid response, try again: ")
# Make it absolute
root = absolutePath(root)

# Move to the git repo
setCurrentDir(root)

# A string to store the markdown
var md: string

# Recursively encodes directory structure as a nested list
proc rec_add_dir_struct(dir: string; level = 0) =
  for kind, path in walkDir(dir):
    # Ignore hidden stuff
    if isHidden(path): continue
    # Add items for folders and files
    if kind == pcDir or kind == pcFile:
      md.add_list_item(lastPathPart(path), level)
      # Recursivly add folder contents
      if kind == pcDir:
        rec_add_dir_struct(path, level + 1)

# Add Directory structure
md.add_line("Directory structure")
rec_add_dir_struct(root)

# Add git graph
const git_graph_cmd = "git log --pretty=fuller --abbrev-commit --all --graph --decorate"
md.add_title("Git Graph", 1)
md.add_code(execCmdEx(git_graph_cmd).output, "git")

# Recursively reads and adds files to the markdown
proc rec_add_files(dir: string; level: int) =
  for kind, path in walkDir(dir):
    # Ignore hidden stuff
    if isHidden(path): continue
    case kind:
      of pcFile:
        # Ignore big files
        if getFileSize(path) > 500000:
          echo "Skipping ", path, " because its too big"
          continue
        let (dir, name, dext) = splitFile(path)
        # remove the dot
        let ext = if dext != "": dext[1..^1] else: ""
        let content = readFile(path)
        # Add the section
        case ext:
          of "", "py", "nim", "nimble", "c", "h", "cpp", "java", "gradle", "md", "json", "js", "html", "ejs", "css", "bat", "ahk", "m":
            md.add_title(name & dext, level)
            md.add_code(content, ext)
          of "classpath", "project", "fxml", "xml":
            md.add_title(name & dext, level)
            md.add_code(content, "xml")
          of "txt", "gitignore", "gitattributes", "cfg", "log", "properties", "config":
            md.add_title(name & dext, level)
            md.add_code(content, "")
          else: discard
      # Recursively handle directories
      of pcDir:
        md.add_title(lastPathPart(path), level)
        rec_add_files(path, level + 1)
      # Don't worry about symblinks and stuff
      else: discard

# Add code files
md.add_title("Code Files", 1)
rec_add_files(root, 2)

# Write to an actual markdown file
writeFile(lastPathPart(root) & ".md", md)