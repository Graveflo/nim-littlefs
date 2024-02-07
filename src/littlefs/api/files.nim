import ../bindings/lfs
import ./common
import ../misc

proc conv(fm: FileMode): cint {. compileTime .} =
  case fm
  of fmWrite:
    result = LfsOpenFlags.LFS_O_CREAT | LfsOpenFlags.LFS_O_WRONLY
  of fmRead:
    result = LfsOpenFlags.LFS_O_RDONLY.cint
  of fmReadWrite:
    result = LfsOpenFlags.LFS_O_CREAT | LfsOpenFlags.LFS_O_RDWR
  of fmReadWriteExisting:
    result = LfsOpenFlags.LFS_O_RDWR.cint
  of fmAppend:
    result = LfsOpenFlags.LFS_O_CREAT | LfsOpenFlags.LFS_O_RDWR | LfsOpenFlags.LFS_O_APPEND

proc open*(lfs: var LittleFs, path: InvString, flags: cint | static FileMode): ref LfsFile =
  let rflag = when flags is FileMode:
      conv(flags)
    else:
      flags
  result = new(LfsFile)
  result.lfs = lfs.lfs.addr
  LFS_ERR_MAYBE: lfs_file_open(result.lfs, result.file.addr, path, rflag)

proc open*(lfs: var LittleFs, path: InvString, mode: LfsFileMode, flags: cint | LfsOpenFlags): ref LfsFile =
  open(lfs, path, mode | flags)

proc close*(file: sink ref LfsFile): LfsErrorCode {. discardable .} =
  LFS_ERR_MAYBE(result): lfs_file_close(file.lfs, file.file.addr)

proc fileExists*(lfs: var LittleFs, path: InvString): bool =
  # This is not optimal
  var f: LfsFileT
  let res = lfs_file_open(lfs.lfs.addr, f.addr, path, LfsOpenFlags.LFS_O_RDONLY.cint)
  if res < 0:
    return false
  else:
    discard lfs_file_close(lfs.lfs.addr, f.addr)
    return true

proc size*(file: ref LfsFile): int =
  lfsFileSize(file.lfs, file.file.addr)

proc sync*(file: ref LfsFile) =
  LFS_ERR_MAYBE: lfs_file_sync(file.lfs, file.file.addr)

proc rewind*(file: ref LfsFile) =
  LFS_ERR_MAYBE: lfs_file_rewind(file.lfs, file.file.addr)

proc seek*(file: ref LfsFile, offset: int, whence: int | LfsWhenceFlags): int {. discardable .} =
  lfs_file_seek(file.lfs, file.file.addr, offset.LfsSOffT, whence.cint)

proc truncate*(file: ref LfsFile, size: int) =
  LFS_ERR_MAYBE: lfs_file_truncate(file.lfs, file.file.addr, size.LfsSizeT)

proc tell*(file: ref LfsFile): int =
  result = lfs_file_tell(file.lfs, file.file.addr)
  LFS_ERR_MAYBE(result)

proc readRaw*(file: ref LfsFile, p: pointer, len: int): int {. discardable .} =
  result = lfsFileRead(file.lfs, file.file.addr, p, len.LfsSizeT)
  LFS_ERR_MAYBE(result)

proc readImpl*[T](file: ref LfsFile, tds: typedesc[T]): T =
  discard readRaw(file, result.addr, sizeof(T))

proc read*[T](file: ref LfsFile): T = readImpl(file, T)

proc readString*(file: ref LfsFile, size: range[1..high(int)]): string =
  result.setLen(size)
  let actual = readRaw(file, result[0].addr, size)
  result.setLen(actual)

proc readAll*(file: ref LfsFile): string =
  readString(file, file.size)

proc writeRaw*(file: ref LfsFile, p: pointer, size: int): int {. discardable .} =
  result = lfs_file_write(file.lfs, file.file.addr, p, size.LfsSizeT)
  LFS_ERR_MAYBE(result)

proc writeString*(file: ref LfsFile, val: string) =
  writeRaw(file, val[0].addr, len(val))

proc write*[T: string](file: ref LfsFile, val: T) =
  mixin write
  write(file, len(val))
  writeString(file, val)

proc write*[T: seq](file: ref LfsFile, val: T) =
  mixin write
  write(file, len(val))
  for x in val:
    write(file, x)

proc write*[T](file: ref LfsFile, val: T) =
  writeRaw(file, val.addr, sizeof(T))
