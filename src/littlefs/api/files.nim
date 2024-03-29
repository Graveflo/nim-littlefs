import ../bindings/lfs
import ./common
import ../misc

export CharArrayLike

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
  LFS_ERR_MAYBE(result): lfs_file_tell(file.lfs, file.file.addr)

proc readRaw*(lfs: ptr LfsT, file: ptr LfsFileT, p: pointer, len: int): int =
  LFS_ERR_MAYBE(result): lfsFileRead(lfs, file, p, len.LfsSizeT)

proc readRaw*(file: ref LfsFile, p: pointer, len: int): int =
  readRaw(file.lfs, file.file.addr, p, len)

proc read*[T](lfs: ptr LfsT, file: ptr LfsFileT): T

proc readImpl*[T](lfs: ptr LfsT, file: ptr LfsFileT, tds: typedesc[T]): T =
  var tmp: T
  discard readRaw(lfs, file, tmp.addr, sizeof(T))
  return tmp

proc readImpl*[T: string](lfs: ptr LfsT, file: ptr LfsFileT, tds: typedesc[T]): T =
  result.setLen(read[int](lfs, file))
  discard readRaw(lfs, file, result[0].addr, len(result))

proc read*[T](lfs: ptr LfsT, file: ptr LfsFileT): T = readImpl(lfs, file, T)

proc read*[T](file: ref LfsFile): T = readImpl(file.lfs, file.file.addr, T)

proc readString*(lfs: ptr LfsT, file: ptr LfsFileT, size: range[1..high(int)]): string =
  result.setLen(size)
  let actual = readRaw(lfs, file, result[0].addr, size)
  result.setLen(actual)

proc readString*(file: ref LfsFile, size: range[1..high(int)]): string =
  readString(file.lfs, file.file.addr, size)

proc readAll*(lfs: ptr LfsT, file: ptr LfsFileT): string =
  readString(lfs, file, lfs_file_size(lfs, file))

proc readAll*(file: ref LfsFile): string =
  readString(file, file.size)

proc writeRaw*(lfs: ptr LfsT, file: ptr LfsFileT, p: pointer, size: int): int {. discardable .} =
  LFS_ERR_MAYBE(result): lfs_file_write(lfs, file, p, size.LfsSizeT).int

proc writeRaw*(file: ref LfsFile, p: pointer, size: int): int {. discardable .} =
  writeRaw(file.lfs, file.file.addr, p, size)

proc writeRaw*[T](lfs: ptr LfsT, file: ptr LfsFileT, p: ptr T): int {. discardable .} =
  writeRaw(lfs, file, p, sizeof(T))

proc writeRaw*[T](file: ref LfsFile, p: ptr T): int {. discardable .} =
  writeRaw(file.lfs, file.file.addr, p, sizeof(T).LfsSizeT)

proc writeString*[T: CharArrayLike](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
  writeRaw(lfs, file, val[0].addr, len(val))

proc writeString*[T: CharArrayLike](file: ref LfsFile, val: T): int {. discardable .} =
  writeString(file.lfs, file.file.addr, val)

proc write*[T: cstring](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
  writeRaw(lfs, file, val, len(val)+1)

proc write*[T: CharArrayLike](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
  mixin write
  result = write(lfs, file, len(val))
  if LfsErrNo < LFS_ERR_OK: return
  result += writeString(lfs, file, val)

proc write*[T: seq](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
  mixin write
  result = write(lfs, file, len(val))
  if LfsErrNo < LFS_ERR_OK: return
  for x in val:
    result += write(lfs, file, x)
    if LfsErrNo < LFS_ERR_OK: return

proc write*[T](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
  writeRaw(lfs, file, val.addr)

proc write*[T](file: ref LfsFile, val: T): int {. discardable .} =
  write(file.lfs, file.file.addr, val)
