import lfs

type
  LfsRambdConfig* {.importc: "struct lfs_rambd_config", header: "bd/lfs_rambd.h", bycopy.} = object
    readSize* {.importc: "read_size".}: LfsSizeT
    progSize* {.importc: "prog_size".}: LfsSizeT
    eraseSize* {.importc: "erase_size".}: LfsSizeT
    eraseCount* {.importc: "erase_count".}: LfsSizeT
    buffer* {.importc: "buffer".}: pointer

  LfsRambdT* {.importc: "lfs_rambd_t", header: "bd/lfs_rambd.h", bycopy.} = object
    buffer* {.importc: "buffer".}: ptr uint8
    cfg* {.importc: "cfg".}: ptr LfsRambdConfig

proc lfsRambdCreate*(cfg: ptr LfsConfig; bdcfg: ptr LfsRambdConfig): cint {.
    importc: "lfs_rambd_create", header: "bd/lfs_rambd.h".}

proc lfsRambdDestroy*(cfg: ptr LfsConfig): cint {.importc: "lfs_rambd_destroy",
    header: "bd/lfs_rambd.h".}

proc lfsRambdRead*(cfg: ptr LfsConfig; `block`: LfsChunkT; off: LfsOffT;
                  buffer: pointer; size: LfsSizeT): cint {.importc: "lfs_rambd_read",
    header: "bd/lfs_rambd.h".}

proc lfsRambdProg*(cfg: ptr LfsConfig; `block`: LfsChunkT; off: LfsOffT;
                  buffer: pointer; size: LfsSizeT): cint {.importc: "lfs_rambd_prog",
    header: "bd/lfs_rambd.h".}

proc lfsRambdErase*(cfg: ptr LfsConfig; `block`: LfsChunkT): cint {.
    importc: "lfs_rambd_erase", header: "bd/lfs_rambd.h".}

proc lfsRambdSync*(cfg: ptr LfsConfig): cint {.importc: "lfs_rambd_sync",
    header: "bd/lfs_rambd.h".}