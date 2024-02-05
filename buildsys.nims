import os

const defaultLfsLoc = thisDir() / "build/littlefs"
const LfsUseNimUtils {. define .} = false
const FuseLibraryName {. define .} = "/usr/lib/libfuse.so"
const FuseVersion {. define .} = "31"
const LfsLoc {. define .} = defaultLfsLoc

const lfsLib = when LfsUseNimUtils: "lfs.o" else: "liblfs.a"

const littleFsGit = "https://github.com/littlefs-project/littlefs"
var ginteracive = true


if not dirExists(thisDir() / "build"):
  mkDir(thisDir() / "build")

template task(name: untyped, descr: string, body:untyped) =
  system.task(name, descr):
    let interacive {. inject .} = ginteracive
    let restore_pwd = getCurrentDir()
    cd(thisDir())
    defer:
      cd(restore_pwd)
    ginteracive = false
    body
    ginteracive = true

proc ensureLfsRepo()=
  if dirExists(LfsLoc) and fileExists(LfsLoc / "lfs.h"): return
  if LfsLoc == defaultLfsLoc:
    cd("build")
    exec("git clone " & quoteShell(littleFsGit))
  if not fileExists(LfsLoc / "lfs.h"):
    quit("Could not locate lfs.h")

proc makeLfs(nv:bool)=
  ensureLfsRepo()
  cd(LfsLoc)
  var mkCommand = "make build"
  if nv:
    if not fileExists(thisDir() / "lfs_util.h"):
      quit("Could not compile with custom lfs_util.h: Not found")
    cpFile(thisDir() / "lfs_util.h", LfsLoc / "lfs_config_nim.h")
    mkCommand &= " CFLAGS=" & quoteShell("-DLFS_CONFIG=lfs_config_nim.h")
  # TODO: This is not the "optimal" way to build.. adjust falgs and detect -d:debug
  exec(mkCommand)
  if nv:
    cpFile(LfsLoc / "lfs.o", thisDir() / "build/lfs.o")
  else:
    cpFile(LfsLoc / "liblfs.a", thisDir() / "build/liblfs.a")

proc ensureLfsLib()=
  if fileExists("build/" & lfsLib): return
  makeLfs(LfsUseNimUtils)

task clean, "Cleans build files":
  rmDir("build")
  mkDir("build")

task buildLfs, "Builds littlefs C sources and grabs libraries":
  makeLfs(false)

task buildLfsNim, "Builds littlefs C sources for use with lfs_nimutl.nim":
  makeLfs(true)

task buildLfsLibs, "Builds both littlefs libraries":
  buildLfsTask()
  buildLfsNimTask()

task buildFuse, "Builds the fuse driver":
  let config = gorgeEx("pkg-config fuse3 --cflags --libs")
  let fv = quoteShell("-D FUSE_USE_VERSION=" & FuseVersion)
  ensureLfsLib()
  let dfe = when LfsUseNimUtils: " -d:LfsUseNimUtils" else: ""
  selfExec("-d:danger -o:build/lfs_fuse --passL:" & "build" / lfsLib &
           " --cincludes:" & quoteShell(LfsLoc) & dfe &
           " --passL:" & quoteShell(FuseLibraryName) & " --passC:" & fv &
           " --passC:" & quoteShell(config.output) & " c src/fuse_lfs.nim")
