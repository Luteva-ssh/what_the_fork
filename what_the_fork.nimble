# Package

version       = "0.1.0"
author        = "Janni Adamski"
description   = "What_the_fork is a terminal tool that analyses forks of a given github repo to extract changes like bugfixes, new features etc."
license       = "MIT"
srcDir        = "src"
bin           = @["what_the_fork"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.2.4"
