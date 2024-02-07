import ../bindings/lfs
import ./common
import ../misc

type
  FsObjectKind = enum
    File, Dir
  FsObject* = object
    case kind*: FsObjectKind
    of File:
      file*: LfsFile
    of Dir:
      dir*: LfsDir

proc mkDir*(lfs: var LittleFs, path: InvString): LfsErrorCode {. discardable .} =
  LFS_ERR_MAYBE(result): lfs_mkdir(lfs.lfs.addr, path.cstring)

proc dirOpen*(lfs: var LittleFs, path: InvString): ref LfsDir =
  result = new(LfsDir)
  result.lfs = lfs.lfs.addr
  LFS_ERR_MAYBE: lfs_dir_open(result.lfs, result.dir.addr, path.cstring)

proc dirClose*(dir: ref LfsDir): LfsErrorCode=
  LFS_ERR_MAYBE: lfs_dir_close(dir.lfs, dir.dir.addr)

proc read*(dir: ref LfsDir): LfsInfo =
  LFS_ERR_MAYBE: lfs_dir_read(dir.lfs, dir.dir.addr, result.addr)

proc seek*(dir: ref LfsDir, offset: int) =
  LFS_ERR_MAYBE: lfs_dir_seek(dir.lfs, dir.dir.addr, offset.LfsOffT)

proc tell*(dir: ref LfsDir): int =
  result = lfs_dir_tell(dir.lfs, dir.dir.addr)
  LFS_ERR_MAYBE: result

proc rewind*(dir: ref LfsDir) =
  LFS_ERR_MAYBE: lfs_dir_rewind(dir.lfs, dir.dir.addr)

iterator contents*(dir: ref LfsDir): LfsInfo =
  dir.rewind()
  var result = dir.read()
  while LfsErrNo.int != 0:
    yield result
    result = dir.read()

const virtDirs = [['.', '\0', '\0'], ['.', '.', '\0']]

iterator walk*(lfs: var LittleFs, path: InvString): LfsInfo {. closure .} =
  var dir = new(LfsDir)
  dir.lfs = lfs.lfs.addr
  if lfs_dir_open(lfs.lfs.addr, dir.dir.addr, path.cstring) == LFS_ERR_OK.int:  # This should prob be an exception
    for x in dir.contents():
      if x.name.toOpenArray(0, 2) notin virtDirs:
        yield x
        if x.kind == LFS_TYPE_DIR:
          let new_path = $cast[cstring](x.name.addr)        
          for y in walk(lfs, path & "/" & new_path):
            yield y
    discard lfs_dir_close(lfs.lfs.addr, dir.dir.addr)

