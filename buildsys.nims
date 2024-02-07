import os

const defaultLfsLoc = thisDir() / "build/littlefs"
const lfsUseNimUtils {. define .} = false
const fuseLibraryName {. define .} = "/usr/lib/libfuse3.so"
const fuseVersion {. define .} = "31"
const lfsLoc {. define .} = defaultLfsLoc


const
  littleFsGit = "https://github.com/littlefs-project/littlefs"
  bLibLfsA = thisDir() / "build/liblfs.a"
  bLibNimLfsA = thisDir() / "build/liblfsNim.a"
  lfsLib = when lfsUseNimUtils: bLibNimLfsA else: bLibLfsA
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
  if dirExists(lfsLoc) and fileExists(lfsLoc / "lfs.h"): return
  if lfsLoc == defaultLfsLoc:
    cd("build")
    exec("git clone " & quoteShell(littleFsGit))
  if not fileExists(lfsLoc / "lfs.h"):
    quit("Could not locate lfs.h")

proc makeLfs(nv:bool)=
  ensureLfsRepo()
  cd(lfsLoc)
  exec("make clean")
  var mkCommand = "make build"
  var cFlags = ""
  if nv:
    if not fileExists(thisDir() / "lfs_util.h"):
      quit("Could not compile with custom lfs_util.h: Not found")
    cpFile(thisDir() / "lfs_util.h", lfsLoc / "lfs_config_nim.h")
    cFlags &= "-DLFS_CONFIG=lfs_config_nim.h "
  when defined(danger):
    cFlags &= "-DLFS_NO_ASSERT -DLFS_NO_WARN -DLFS_NO_ERROR "
  if cflags.len > 0:
    mkCommand &= " CFLAGS=" & quoteShell(cflags)
  exec(mkCommand)
  cpFile(lfsLoc / "liblfs.a", if nv: bLibNimLfsA else: bLibLfsA)

proc ensureLfsLib()=
  if fileExists(lfsLib): return
  makeLfs(lfsUseNimUtils)

task clean, "Cleans build files":
  rmDir("build")
  mkDir("build")

task buildLfs, "Builds littlefs C sources and grabs libraries":
  if fileExists(bLibLfsA):
    rmFile(bLibLfsA)
  makeLfs(false)

task buildLfsNim, "Builds littlefs C sources for use with lfs_nimutl.nim":
  if fileExists(bLibNimLfsA):
    rmFile(bLibNimLfsA)
  makeLfs(true)

task buildLfsLibs, "Builds both littlefs libraries":
  buildLfsTask()
  buildLfsNimTask()

task buildFuse, "Builds the fuse driver":
  let config = gorgeEx("pkg-config fuse3 --cflags --libs")
  let fv = quoteShell("-DFUSE_USE_VERSION=" & fuseVersion)
  ensureLfsLib()
  let dfe = when lfsUseNimUtils: " -d:LfsUseNimUtils" else: ""
  var cmd = " -o:build/lfs_fuse --passL:" & lfsLib &
            " -d:FUSE_USE_VERSION:" & fuseVersion &
            " --cincludes:" & quoteShell(lfsLoc) & dfe &
            " --passL:" & quoteShell(fuseLibraryName) & " --passC:" & fv &
            " --passC:" & quoteShell(config.output) & " c src/fuse_lfs.nim"
  when defined(debug):
    cmd = "-d:debug --stackTrace:on" & cmd
  elif defined(release):
    cmd = "-d:release" & cmd
  else:
    cmd = "-d:danger" & cmd
  selfExec(cmd)
