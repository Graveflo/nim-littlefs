# Package

version       = "0.1.0"
author        = "Ryan McConnell"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.1.1"

requires "cligen"

include "./buildsys.nims"

task install, "builds stuff":
  buildLfsLibsTask()
