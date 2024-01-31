

import lfs

type
  LfsEmubdBadblockBehaviorT* {.size: sizeof(cint).} = enum
    LFS_EMUBD_BADBLOCK_PROGERROR, LFS_EMUBD_BADBLOCK_ERASEERROR,
    LFS_EMUBD_BADBLOCK_READERROR, LFS_EMUBD_BADBLOCK_PROGNOOP,
    LFS_EMUBD_BADBLOCK_ERASENOOP

  LfsEmubdPowerlossBehaviorT* {.size: sizeof(cint).} = enum
    LFS_EMUBD_POWERLOSS_NOOP

  LfsEmubdIoT* = uint64
  LfsEmubdSioT* = int64
  LfsEmubdWearT* = uint32
  LfsEmubdSwearT* = int32
  LfsEmubdPowercyclesT* = uint32
  LfsEmubdSpowercyclesT* = int32
  LfsEmubdSleepT* = uint64
  LfsEmubdSsleepT* = int64

  LfsEmubdConfig* {.importc: "lfs_emubd_config", header: "lfs_emubd.h", bycopy.} = object
    readSize* {.importc: "read_size".}: LfsSizeT
    progSize* {.importc: "prog_size".}: LfsSizeT
    eraseSize* {.importc: "erase_size".}: LfsSizeT
    eraseCount* {.importc: "erase_count".}: LfsSizeT
    eraseValue* {.importc: "erase_value".}: int32
    eraseCycles* {.importc: "erase_cycles".}: uint32
    badblockBehavior* {.importc: "badblock_behavior".}: LfsEmubdBadblockBehaviorT
    powerCycles* {.importc: "power_cycles".}: LfsEmubdPowercyclesT
    powerlossBehavior* {.importc: "powerloss_behavior".}: LfsEmubdPowerlossBehaviorT
    powerlossCb* {.importc: "powerloss_cb".}: proc (a1: pointer)
    powerlossData* {.importc: "powerloss_data".}: pointer
    trackBranches* {.importc: "track_branches".}: bool
    diskPath* {.importc: "disk_path".}: cstring
    readSleep* {.importc: "read_sleep".}: LfsEmubdSleepT
    progSleep* {.importc: "prog_sleep".}: LfsEmubdSleepT
    eraseSleep* {.importc: "erase_sleep".}: LfsEmubdSleepT

  LfsEmubdBlockT* {.importc: "lfs_emubd_block_t", header: "lfs_emubd.h", bycopy.} = object
    rc* {.importc: "rc".}: uint32
    wear* {.importc: "wear".}: LfsEmubdWearT
    data* {.importc: "data".}: UncheckedArray[uint8]

  LfsEmubdDiskT* {.importc: "lfs_emubd_disk_t", header: "lfs_emubd.h", bycopy.} = object
    rc* {.importc: "rc".}: uint32
    fd* {.importc: "fd".}: cint
    scratch* {.importc: "scratch".}: ptr uint8

  LfsEmubdT* {.importc: "lfs_emubd_t", header: "lfs_emubd.h", bycopy.} = object
    blocks* {.importc: "blocks".}: ptr ptr LfsEmubdBlockT
    readed* {.importc: "readed".}: LfsEmubdIoT
    proged* {.importc: "proged".}: LfsEmubdIoT
    erased* {.importc: "erased".}: LfsEmubdIoT
    powerCycles* {.importc: "power_cycles".}: LfsEmubdPowercyclesT
    disk* {.importc: "disk".}: ptr LfsEmubdDiskT
    cfg* {.importc: "cfg".}: ptr LfsEmubdConfig



proc lfsEmubdCreate*(cfg: ptr LfsConfig; bdcfg: ptr LfsEmubdConfig): cint {.
    importc: "lfs_emubd_create", header: "lfs_emubd.h".}

proc lfsEmubdDestroy*(cfg: ptr LfsConfig): cint {.importc: "lfs_emubd_destroy",
    header: "lfs_emubd.h".}

proc lfsEmubdRead*(cfg: ptr LfsConfig; `block`: LfsChunkT; off: LfsOffT;
                  buffer: pointer; size: LfsSizeT): cint {.importc: "lfs_emubd_read",
    header: "lfs_emubd.h".}

proc lfsEmubdProg*(cfg: ptr LfsConfig; `block`: LfsChunkT; off: LfsOffT;
                  buffer: pointer; size: LfsSizeT): cint {.importc: "lfs_emubd_prog",
    header: "lfs_emubd.h".}

proc lfsEmubdErase*(cfg: ptr LfsConfig; `block`: LfsChunkT): cint {.
    importc: "lfs_emubd_erase", header: "lfs_emubd.h".}

proc lfsEmubdSync*(cfg: ptr LfsConfig): cint {.importc: "lfs_emubd_sync",
    header: "lfs_emubd.h".}

proc lfsEmubdCrc*(cfg: ptr LfsConfig; `block`: LfsChunkT; crc: ptr uint32): cint {.
    importc: "lfs_emubd_crc", header: "lfs_emubd.h".}

proc lfsEmubdBdcrc*(cfg: ptr LfsConfig; crc: ptr uint32): cint {.
    importc: "lfs_emubd_bdcrc", header: "lfs_emubd.h".}

proc lfsEmubdReaded*(cfg: ptr LfsConfig): LfsEmubdSioT {.importc: "lfs_emubd_readed",
    header: "lfs_emubd.h".}

proc lfsEmubdProged*(cfg: ptr LfsConfig): LfsEmubdSioT {.importc: "lfs_emubd_proged",
    header: "lfs_emubd.h".}

proc lfsEmubdErased*(cfg: ptr LfsConfig): LfsEmubdSioT {.importc: "lfs_emubd_erased",
    header: "lfs_emubd.h".}

proc lfsEmubdSetreaded*(cfg: ptr LfsConfig; readed: LfsEmubdIoT): cint {.
    importc: "lfs_emubd_setreaded", header: "lfs_emubd.h".}

proc lfsEmubdSetproged*(cfg: ptr LfsConfig; proged: LfsEmubdIoT): cint {.
    importc: "lfs_emubd_setproged", header: "lfs_emubd.h".}

proc lfsEmubdSeterased*(cfg: ptr LfsConfig; erased: LfsEmubdIoT): cint {.
    importc: "lfs_emubd_seterased", header: "lfs_emubd.h".}

proc lfsEmubdWear*(cfg: ptr LfsConfig; `block`: LfsChunkT): LfsEmubdSwearT {.
    importc: "lfs_emubd_wear", header: "lfs_emubd.h".}

proc lfsEmubdSetwear*(cfg: ptr LfsConfig; `block`: LfsChunkT; wear: LfsEmubdWearT): cint {.
    importc: "lfs_emubd_setwear", header: "lfs_emubd.h".}

proc lfsEmubdPowercycles*(cfg: ptr LfsConfig): LfsEmubdSpowercyclesT {.
    importc: "lfs_emubd_powercycles", header: "lfs_emubd.h".}

proc lfsEmubdSetpowercycles*(cfg: ptr LfsConfig; powerCycles: LfsEmubdPowercyclesT): cint {.
    importc: "lfs_emubd_setpowercycles", header: "lfs_emubd.h".}

proc lfsEmubdCopy*(cfg: ptr LfsConfig; copy: ptr LfsEmubdT): cint {.
    importc: "lfs_emubd_copy", header: "lfs_emubd.h".}