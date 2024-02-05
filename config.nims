import os

--noNimblePath 
switch("cincludes", thisDir() / "build/littlefs")
when defined(LfsUseNimUtils):
  switch("passL", thisDir() / "build/lfs.o")
else:
  switch("passL", thisDir() / "build/liblfs.a")
--gc:arc
--listCmd
