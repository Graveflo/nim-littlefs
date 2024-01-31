import ../bindings/lfs
import ./common

type
  FsObjectKind = enum
    File, Dir
  FsObject* = object
    case kind*: FsObjectKind
    of File:
      file*: LfsFile
    of Dir:
      dir*: LfsDir

proc mkDir*(lfs: var LittleFs, path: string): LfsErrorCode {. discardable .} =
  result = lfs_mkdir(lfs.lfs.addr, path.cstring).LfsErrorCode

proc dirOpen*(lfs: var LittleFs, path: string): ref LfsDir =
  result = new(LfsDir)
  result.lfs = lfs.lfs.addr
  LfsErrNo = lfs_dir_open(result.lfs, result.dir.addr, path.cstring).LfsErrorCode

proc read*(dir: ref LfsDir): LfsInfo =
  LfsErrNo = lfs_dir_read(dir.lfs, dir.dir.addr, result.addr).LfsErrorCode

proc seek*(dir: ref LfsDir, offset: int) =
  LfsErrNo = lfs_dir_seek(dir.lfs, dir.dir.addr, offset.LfsOffT).LfsErrorCode

proc tell*(dir: ref LfsDir): int =
  result = lfs_dir_tell(dir.lfs, dir.dir.addr)
  if result > LFS_ERR_OK.int:
    LfsErrNo = LFS_ERR_OK
  else:
    LfsErrNo = result.LfsErrorCode

proc rewind*(dir: ref LfsDir) =
  LfsErrNo = lfs_dir_rewind(dir.lfs, dir.dir.addr).LfsErrorCode

iterator contents*(dir: ref LfsDir): LfsInfo =
  dir.rewind()
  var result = dir.read()
  while LfsErrNo.int != 0:
    yield result
    result = dir.read()

const virtDirs = [['.', '\0', '\0'], ['.', '.', '\0']]

proc contains[N;M;T](sol: array[N, array[M,T]], sub: openArray[T]): bool=
  for x in sol:
    var
      flag = true
      i = 0
    while (i < len(x)) and flag:
      flag = flag and (sub[i] == x[i])
      inc i
    if flag: return true
  return false

iterator walk*(lfs: var LittleFs, path: string): LfsInfo {. closure .} =
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

