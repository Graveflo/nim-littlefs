# Package

version       = "0.2.0"
author        = "Ryan McConnell"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.1.1"

requires "cligen"

# import "./buildsys.nims" this doesn't seem to work

task build, "builds stuff":  # this doesnt seem to work automatically
  exec("nim buildLfsLibs buildsys.nims")
