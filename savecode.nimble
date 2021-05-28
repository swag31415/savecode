# Package
version       = "0.1"
author        = "swag31415"
description   = "Turn an old Git repo into a single Markdown file ready to be archived"
license       = "MIT"
srcDir        = "src"
bin           = @["savecode"]
backend       = "cpp"

# Dependencies
requires "nim >= 1.4.0"
