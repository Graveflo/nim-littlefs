import ../bindings/lfs

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


var LfsErrNo* = LFS_ERR_OK

proc `==`*(a,b: LfsType): bool {. borrow .}
proc `==`*(a,b: LfsErrorCode): bool {. borrow .}

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

proc boot(lfs: var LfsT, cfg: ptr LfsConfig): int =
  let firstMountErr = lfsMount(lfs.addr, cfg)
  if firstMountErr < 0:
    discard lfsFormat(lfs.addr, cfg)
    result = lfsMount(lfs.addr, cfg)
  else:
    result = firstMountErr

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
  result = boot(lfs.lfs, lfs.cfg.addr)

proc `or`*(a, b: CompatFEnumT | cint): cint = a.cint or b.cint
proc `|`*(a, b: CompatFEnumT | cint): cint = a.cint or b.cint

proc remove*(lfs: var LittleFs, path: string): LfsErrorCode =
  lfs_remove(lfs.lfs.addr, path.cstring).LfsErrorCode

proc rename*(lfs: var LittleFs, old_path: string, new_path: string): LfsErrorCode =
  lfs_rename(lfs.lfs.addr, old_path.cstring, new_path.cstring).LfsErrorCode

proc stat*(lfs: var LittleFs, path: string): LfsInfo =
  LfsErrNo = lfs_stat(lfs.lfs.addr, path.cstring, result.addr).LfsErrorCode
