import std/[os, macros]
import ../bindings/lfs
import ../misc

const lfsUseNimUtils {. define .} = false
when lfsUseNimUtils:
  import ../bindings/lfs_nimutil
  export lfs_nimutil

type
  LittleFs* = object
    lfs*: LfsT
    cfg*: LfsConfig
  LfsFileMode* = enum
    LFS_O_RDONLY = 1,         # Open a file as read only
    LFS_O_WRONLY = 2,         # Open a file as write only
    LFS_O_RDWR   = 3,         # Open a file as read and write
  CompatFEnumT = LfsOpenFlags | LfsFileMode
  LfsFile* = object
    file*: LfsFileT
    lfs*: ptr LfsT
  LfsDir* = object
    dir*: LfsDirT
    lfs*: ptr LfsT
  LfsError* = object of CatchableError
    code: LfsErrorCode


var LfsErrNo* {. threadvar .}: LfsErrorCode

proc `==`*(a,b: LfsType): bool {. borrow .}
proc `==`*(a,b: LfsErrorCode): bool {. borrow .}

template LFS_ERR_MAYBE*(err: LfsErrorCode | int | cint): untyped =
  LfsErrNo = err.LfsErrorCode

#macro LFS_ERR_MAYBE*(setme, body: untyped): untyped =
#  result = quote do:
#    let err = `body`
#    LFS_ERR_MAYBE(err)
#    `setme` = err.LfsErrorCode

template LFS_ERR_MAYBE*(setme, body: untyped): untyped=
  let err = LfsErrorCode(body)
  LFS_ERR_MAYBE(err)
  `setme` = err

template LFS_ERR_MAYBE*(err: LfsErrorCode | int | cint, msg: string): untyped=
  LFS_ERR_MAYBE(err)
  # TODO: This echo is temporary
  echo "error: ", msg

proc closeAllOpen(x: ptr LfsT, kind: LfsType)=
  template op(cll, cst: untyped)=
    var ptrMList: ptr lfs_mlist = x.mlist
    while not ptrMList.isNil:
      if ptrMList.kind == kind:
        discard cll(x, cast[ptr cst](ptrMList))
        ptrMList = x.mlist
      else:
        ptrMList = ptrMList.next
  if kind == LFS_TYPE_DIR:
    op(lfs_dir_close, LfsDirT)
  elif kind == LFS_TYPE_REG:
    op(lfs_file_close, LfsFileT)

proc boot(lfs: ptr LfsT, cfg: ptr LfsConfig): int =
  let firstMountErr = lfsMount(lfs, cfg)
  if firstMountErr < 0:
    discard lfsFormat(lfs, cfg)
    result = lfsMount(lfs, cfg)
  else:
    result = firstMountErr

proc mount*(lfs: var LittleFs): LfsErrorCode {. discardable .}=
  LFS_ERR_MAYBE: lfsMount(lfs.lfs.addr, lfs.cfg.addr)
  return LfsErrNo

proc `=destroy`(x: LittleFs) =
  if x.lfs.cfg == nil: return
  if x.lfs.cfg.read_buffer == nil or x.lfs.cfg.prog_buffer == nil or
     x.lfs.cfg.lookahead_buffer == nil:
    closeAllOpen(x.lfs.addr, LFS_TYPE_REG)
    closeAllOpen(x.lfs.addr, LFS_TYPE_DIR)
    discard lfsUnmount(x.lfs.addr)

proc `=copy`(x: var LittleFs, y: LittleFs) {. error .}
proc `=dup`(x: LittleFs): LittleFs {. error .}

proc boot*(lfs: var LittleFs): int {. discardable .} =
  result = boot(lfs.lfs.addr, lfs.cfg.addr)

proc `or`*(a, b: CompatFEnumT | cint): cint = a.cint or b.cint
proc `|`*(a, b: CompatFEnumT | cint): cint = a.cint or b.cint

proc remove*(lfs: var LittleFs, path: InvString): LfsErrorCode =
  LFS_ERR_MAYBE(result): lfs_remove(lfs.lfs.addr, path.cstring)

proc rename*(lfs: var LittleFs, old_path: InvString, new_path: InvString): LfsErrorCode =
  LFS_ERR_MAYBE(result): lfs_rename(lfs.lfs.addr, old_path.cstring, new_path.cstring)

proc stat*(lfs: var LittleFs, path: InvString): LfsInfo =
  LFS_ERR_MAYBE: lfs_stat(lfs.lfs.addr, path.cstring, result.addr)

proc stat*(lfs: var LittleFs): LfsFsInfo=
  LFS_ERR_MAYBE: lfs_fs_stat(lfs.lfs.addr, result.addr)

proc size*(lfs: var LittleFS): int =
  LFS_ERR_MAYBE: lfs_fs_size(lfs.lfs.addr)
  return LfsErrNo.int
