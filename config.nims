import os

# current bug in nim makes `thisDir()` not work the same as `currentSourcePath`

switch("cincludes", currentSourcePath.parentDir() / "build/littlefs")
when defined(lfsUseNimUtils):
  discard # should be handled by common.nim
  switch("passL", currentSourcePath.parentDir() / "build/liblfsNim.a")
else:
  discard # should be handled by common.nim
  switch("passL", currentSourcePath.parentDir() / "build/liblfs.a")
