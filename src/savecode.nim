## savecode

import markdown
import os
from strutils import splitLines
from strformat import `&`
from sequtils import anyIt, applyIt
from osproc import execCmdEx

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

# the output file's name
let md_filename = lastPathPart(root) & ".md"
# A string to store the markdown
var md: string

# Get untracked files
var untracked = execCmdEx("git ls-files -o --directory").output.splitLines()
# Also ignore the markdown file if it already exists
if fileExists(md_filename): untracked.add(md_filename)
# Make all paths absolute
untracked.applyIt(absolutePath(it))

# The stack used for dfs through the directory
var dir_stack = @[(root, 0)]
# A md string to store transribed files that will be appended to the main md string
var code_md: string

# Add Directory structure and populate `code_md`
md.add_line("Directory structure")
while len(dir_stack) > 0:
  let (dir, lvl) = dir_stack.pop()
  let dir_name = lastPathPart(dir)
  md.add_list_item(&"[{dir_name}](#{dir_name})", lvl)
  code_md.add_title(dir_name, lvl)
  for kind, path in walkDir(dir):
    # Ignore hidden files
    if isHidden(path): continue
    # Get a name
    let name = lastPathPart(path)
    # Ignore untracked files but add them to the directory structure
    # Do the same for large files
    if untracked.anyIt(sameFile(it, path)) or fileExists(path) and getFileSize(path) > 50 * 1024:
      md.add_list_item(name, lvl + 1)
      continue
    # Handle Tracked files and folders
    case kind:
      of pcDir: # Add folders to the stack
        dir_stack.add((path, lvl + 1))
      of pcFile: # Parse files according to extension
        let ext = path[searchExtPos(path)+1..^1]
        let content = readFile(path)
        case ext:
          of "", "py", "nim", "nimble", "c", "h", "cpp", "java", "gradle", "md", "json", "js", "css", "bat", "ahk", "m":
            code_md.add_title(name, lvl + 1)
            code_md.add_code(content, ext)
          of "ejs", "html":
            code_md.add_title(name, lvl + 1)
            code_md.add_code(content, "html")
          of "classpath", "project", "fxml", "xml":
            code_md.add_title(name, lvl + 1)
            code_md.add_code(content, "xml")
          of "txt", "gitignore", "gitattributes", "cfg", "log", "properties", "config":
            code_md.add_title(name, lvl + 1)
            code_md.add_code(content, "")
          else: continue
        md.add_list_item(&"[{name}](#{name})", lvl + 1)
      else: discard

# Add git graph
const git_graph_cmd = "git log --pretty=fuller --abbrev-commit --all --graph --decorate"
md.add_title("Git Graph", 1)
md.add_code(execCmdEx(git_graph_cmd).output, "git")

# Move back to the directory of this exe
setCurrentDir(getAppDir())
# Write to an actual markdown file
writeFile(md_filename, md & code_md)