import lfs

type
  LfsFilebdConfig* {.importc: "lfs_filebd_config", header: "lfs_filebd.h", bycopy.} = object
    readSize* {.importc: "read_size".}: LfsSizeT
    progSize* {.importc: "prog_size".}: LfsSizeT
    eraseSize* {.importc: "erase_size".}: LfsSizeT
    eraseCount* {.importc: "erase_count".}: LfsSizeT

  LfsFilebdT* {.importc: "lfs_filebd_t", header: "lfs_filebd.h", bycopy.} = object
    fd* {.importc: "fd".}: cint
    cfg* {.importc: "cfg".}: ptr LfsFilebdConfig

proc lfsFilebdCreate*(cfg: ptr LfsConfig; path: cstring; bdcfg: ptr LfsFilebdConfig): cint {.
    importc: "lfs_filebd_create", header: "lfs_filebd.h".}

proc lfsFilebdDestroy*(cfg: ptr LfsConfig): cint {.importc: "lfs_filebd_destroy",
    header: "lfs_filebd.h".}

proc lfsFilebdRead*(cfg: ptr LfsConfig; `block`: LfsChunkT; off: LfsOffT;
                   buffer: pointer; size: LfsSizeT): cint {.
    importc: "lfs_filebd_read", header: "lfs_filebd.h".}

proc lfsFilebdProg*(cfg: ptr LfsConfig; `block`: LfsChunkT; off: LfsOffT;
                   buffer: pointer; size: LfsSizeT): cint {.
    importc: "lfs_filebd_prog", header: "lfs_filebd.h".}

proc lfsFilebdErase*(cfg: ptr LfsConfig; `block`: LfsChunkT): cint {.
    importc: "lfs_filebd_erase", header: "lfs_filebd.h".}

proc lfsFilebdSync*(cfg: ptr LfsConfig): cint {.importc: "lfs_filebd_sync",
    header: "lfs_filebd.h".}