import ../misc

const
  LFS_VERSION* = 0x00020008
  LFS_VERSION_MAJOR* = (0xffff and (LFS_VERSION shr 16))
  LFS_VERSION_MINOR* = (0xffff and (LFS_VERSION shr 0))

  LFS_DISK_VERSION* = 0x00020001
  LFS_DISK_VERSION_MAJOR* = (0xffff and (LFS_DISK_VERSION shr 16))
  LFS_DISK_VERSION_MINOR* = (0xffff and (LFS_DISK_VERSION shr 0))


type
  LfsSizeT* = uint32
  LfsOffT* = uint32
  LfsSsizeT* = int32
  LfsSoffT* = int32
  LfsChunkT* = uint32
  LfsErrorCode* = distinct cint
  LfsType* = distinct cint

const LFS_NAME_MAX* = when not defined(LFS_NAME_MAX): 255
                      elif not defined(LFS_FILE_MAX): 2147483647
                      elif not defined(LFS_ATTR_MAX): 1022

importCConst LfsErrorCode, "lfs.h":
  LFS_ERR_CORRUPT = -84
  LFS_ERR_NOATTR = -61
  LFS_ERR_NOTEMPTY = -39
  LFS_ERR_NAMETOOLONG = -36
  LFS_ERR_NOSPC = -28
  LFS_ERR_FBIG = -27
  LFS_ERR_INVAL = -22
  LFS_ERR_ISDIR = -21
  LFS_ERR_NOTDIR = -20
  LFS_ERR_EXIST = -17
  LFS_ERR_NOMEM = -12
  LFS_ERR_BADF = -9
  LFS_ERR_IO = -5
  LFS_ERR_NOENT = -2
  LFS_ERR_OK = 0

importCConst LfsType, "lfs.h":
  LFS_TYPE_NAME = 0x000
  LFS_TYPE_REG = 0x001
  LFS_TYPE_DIR = 0x002
  LFS_TYPE_SUPERBLOCK = 0x0ff
  LFS_TYPE_FROM = 0x100
  LFS_FROM_MOVE = 0x101
  LFS_FROM_USERATTRS = 0x102
  LFS_TYPE_STRUCT = 0x200
  LFS_TYPE_INLINESTRUCT = 0x201
  LFS_TYPE_CTZSTRUCT = 0x202
  LFS_TYPE_USERATTR = 0x300
  LFS_TYPE_SPLICE = 0x400
  LFS_TYPE_CREATE = 0x401
  LFS_TYPE_DELETE = 0x4ff
  LFS_TYPE_CRC = 0x500
  LFS_TYPE_FCRC = 0x5ff
  LFS_TYPE_TAIL = 0x600
  LFS_TYPE_HARDTAIL = 0x601
  LFS_TYPE_GLOBALS = 0x700
  LFS_TYPE_MOVESTATE = 0x7ff

#type
#[   LfsError* {.size: sizeof(cint).} = enum
    LFS_ERR_CORRUPT = -84, LFS_ERR_NOATTR = -61, LFS_ERR_NOTEMPTY = -39,
    LFS_ERR_NAMETOOLONG = -36, LFS_ERR_NOSPC = -28, LFS_ERR_FBIG = -27,
    LFS_ERR_INVAL = -22, LFS_ERR_ISDIR = -21, LFS_ERR_NOTDIR = -20, LFS_ERR_EXIST = -17,
    LFS_ERR_NOMEM = -12, LFS_ERR_BADF = -9, LFS_ERR_IO = -5, LFS_ERR_NOENT = -2,
    LFS_ERR_OK = 0 ]#

  #[ LfsType* {.size: sizeof(cint).} = enum
    LFS_TYPE_NAME = 0x000, LFS_TYPE_REG = 0x001, LFS_TYPE_DIR = 0x002,
    LFS_TYPE_SUPERBLOCK = 0x0ff, LFS_TYPE_FROM = 0x100, LFS_FROM_MOVE = 0x101,
    LFS_FROM_USERATTRS = 0x102, LFS_TYPE_STRUCT = 0x200,
    LFS_TYPE_INLINESTRUCT = 0x201, LFS_TYPE_CTZSTRUCT = 0x202,
    LFS_TYPE_USERATTR = 0x300, LFS_TYPE_SPLICE = 0x400, LFS_TYPE_CREATE = 0x401,
    LFS_TYPE_DELETE = 0x4ff, LFS_TYPE_CRC = 0x500, LFS_TYPE_FCRC = 0x5ff,
    LFS_TYPE_TAIL = 0x600, LFS_TYPE_HARDTAIL = 0x601, LFS_TYPE_GLOBALS = 0x700,
    LFS_TYPE_MOVESTATE = 0x7ff ]#

let
  LFS_FROM_NOOP* = LFS_TYPE_NAME
  LFS_TYPE_DIRSTRUCT* = LFS_TYPE_STRUCT
  LFS_TYPE_CCRC* = LFS_TYPE_CRC
  LFS_TYPE_SOFTTAIL* = LFS_TYPE_TAIL


type
  LfsOpenFlags* {.size: sizeof(cint).} = enum
    LFS_O_RDONLY = 1,         # Open a file as read only
    LFS_O_WRONLY = 2,         # Open a file as write only
    LFS_O_RDWR   = 3,         # Open a file as read and write
    LFS_O_CREAT  = 0x0100,    # Create a file if it does not exist
    LFS_O_EXCL   = 0x0200,    # Fail if a file already exists
    LFS_O_TRUNC  = 0x0400,    # Truncate the existing file to zero size
    LFS_O_APPEND = 0x0800,    # Move to end of file on every write
    # internally used flags
    LFS_F_DIRTY   = 0x010000,  #File does not match storage
    LFS_F_WRITING = 0x020000,  # File has been written since last flush
    LFS_F_READING = 0x040000,  # File has been read since last flush
    LFS_F_ERRED   = 0x080000,  # An error occurred during write
    LFS_F_INLINE  = 0x100000,  # Currently inlined in directory entry

  LfsWhenceFlags* {.size: sizeof(cint).} = enum
    LFS_SEEK_SET = 0, LFS_SEEK_CUR = 1, LFS_SEEK_END = 2

  LfsConfig* {.importc: "struct lfs_config", header: "lfs.h", acyclic.} = object
    context* {.importc: "context".}: pointer
    read*: proc (c: ptr LfsConfig; chunk: LfsChunkT; off: LfsOffT; buffer: pointer; size: LfsSizeT) : cint {. cdecl .}
    prog*: proc (c: ptr LfsConfig; chunk: LfsChunkT; off: LfsOffT; buffer: pointer; size: LfsSizeT): cint {. cdecl .}
    erase*: proc (c: ptr LfsConfig; chunk: LfsChunkT): cint {. cdecl .}
    sync*: proc (c: ptr LfsConfig): cint {. cdecl .}
    when defined(LFS_THREADSAFE):
      lock*: proc (c: ptr LfsConfig): cint {. cdecl .}
      unlock*: proc (c: ptr LfsConfig): cint {. cdecl .}
    readSize* {.importc: "read_size".}: LfsSizeT
    progSize* {.importc: "prog_size".}: LfsSizeT
    blockSize* {.importc: "block_size".}: LfsSizeT
    blockCount* {.importc: "block_count".}: LfsSizeT
    blockCycles* {.importc: "block_cycles".}: int32
    cacheSize* {.importc: "cache_size".}: LfsSizeT
    lookaheadSize* {.importc: "lookahead_size".}: LfsSizeT
    readBuffer* {.importc: "read_buffer".}: pointer
    progBuffer* {.importc: "prog_buffer".}: pointer
    lookaheadBuffer* {.importc: "lookahead_buffer".}: pointer
    nameMax* {.importc: "name_max".}: LfsSizeT
    fileMax* {.importc: "file_max".}: LfsSizeT
    attrMax* {.importc: "attr_max".}: LfsSizeT
    metadataMax* {.importc: "metadata_max".}: LfsSizeT
    when defined(LFS_MULTIVERSION):
      diskVersion* {.importc: "disk_version", header: "lfs.h".}: uint32

type
  LfsInfo* {.importc: "struct lfs_info", header: "lfs.h", bycopy.} = object
    kind* {.importc: "type".}: LfsType
    size* {.importc: "size".}: LfsSizeT
    name* {.importc: "name".}: array[LFS_NAME_MAX + 1, char]

  LfsFsinfo* {.importc: "lfs_fsinfo", header: "lfs.h", bycopy.} = object
    diskVersion* {.importc: "disk_version".}: uint32
    blockSize* {.importc: "block_size".}: LfsSizeT
    blockCount* {.importc: "block_count".}: LfsSizeT
    nameMax* {.importc: "name_max".}: LfsSizeT
    fileMax* {.importc: "file_max".}: LfsSizeT
    attrMax* {.importc: "attr_max".}: LfsSizeT

  LfsAttr* {.importc: "lfs_attr", header: "lfs.h", bycopy.} = object
    kind* {.importc: "type".}: uint8
    buffer* {.importc: "buffer".}: pointer
    size* {.importc: "size".}: LfsSizeT

  LfsFileConfig* {.importc: "lfs_file_config", header: "lfs.h", bycopy.} = object
    buffer* {.importc: "buffer".}: pointer
    attrs* {.importc: "attrs".}: ptr LfsAttr
    attrCount* {.importc: "attr_count".}: LfsSizeT

  LfsCacheT* {.importc: "lfs_cache_t", header: "lfs.h", bycopy.} = object
    chunk* {.importc: "block".}: LfsChunkT
    off* {.importc: "off".}: LfsOffT
    size* {.importc: "size".}: LfsSizeT
    buffer* {.importc: "buffer".}: ptr uint8

  LfsMdirT* {.importc: "lfs_mdir_t", header: "lfs.h", bycopy.} = object
    pair* {.importc: "pair".}: array[2, LfsChunkT]
    rev* {.importc: "rev".}: uint32
    off* {.importc: "off".}: LfsOffT
    etag* {.importc: "etag".}: uint32
    count* {.importc: "count".}: uint16
    erased* {.importc: "erased".}: bool
    split* {.importc: "split".}: bool
    tail* {.importc: "tail".}: array[2, LfsChunkT]

  LfsDirT* {.importc: "lfs_dir_t", header: "lfs.h", bycopy.} = object
    next* {.importc: "next".}: ptr LfsDirT
    id* {.importc: "id".}: uint16
    kind* {.importc: "type".}: LfsType
    m* {.importc: "m".}: LfsMdirT
    pos* {.importc: "pos".}: LfsOffT
    head* {.importc: "head".}: array[2, LfsChunkT]



type
  lfs_ctz_lfs_1* {.importc: "lfs_file_t::no_name", header: "lfs.h", bycopy.} = object
    head* {.importc: "head".}: LfsChunkT
    size* {.importc: "size".}: LfsSizeT

  LfsFileT* {.importc: "lfs_file_t", header: "lfs.h".} = object
    next* {.importc: "next".}: ptr LfsFileT
    id* {.importc: "id".}: uint16
    kind* {.importc: "type".}: LfsType
    m* {.importc: "m".}: LfsMdirT
    ctz* {.importc: "ctz".}: lfs_ctz_lfs_1
    flags* {.importc: "flags".}: uint32
    pos* {.importc: "pos".}: LfsOffT
    chunk* {.importc: "block".}: LfsChunkT
    off* {.importc: "off".}: LfsOffT
    cache* {.importc: "cache".}: LfsCacheT
    cfg* {.importc: "cfg".}: ptr LfsFileConfig

  LfsSuperblockT* {.importc: "lfs_superblock_t", header: "lfs.h", bycopy.} = object
    version* {.importc: "version".}: uint32
    blockSize* {.importc: "block_size".}: LfsSizeT
    blockCount* {.importc: "block_count".}: LfsSizeT
    nameMax* {.importc: "name_max".}: LfsSizeT
    fileMax* {.importc: "file_max".}: LfsSizeT
    attrMax* {.importc: "attr_max".}: LfsSizeT

  LfsGstateT* {.importc: "lfs_gstate_t", header: "lfs.h", bycopy.} = object
    tag* {.importc: "tag".}: uint32
    pair* {.importc: "pair".}: array[2, LfsChunkT]



type
  lfs_mlist* {.importc: "struct lfs_mlist", header: "lfs.h", bycopy.} = object
    next* {.importc: "next".}: ptr lfs_mlist
    id* {.importc: "id".}: uint16
    kind* {.importc: "type".}: LfsType
    m* {.importc: "m".}: LfsMdirT

  lfs_free_lfs_5* {.importc: "lfs_t::no_name", header: "lfs.h", bycopy.} = object
    off* {.importc: "off".}: LfsChunkT
    size* {.importc: "size".}: LfsChunkT
    i* {.importc: "i".}: LfsChunkT
    ack* {.importc: "ack".}: LfsChunkT
    buffer* {.importc: "buffer".}: ptr uint32

  LfsT* {.importc: "lfs_t", header: "lfs.h".} = object
    rcache* {.importc: "rcache".}: LfsCacheT
    pcache* {.importc: "pcache".}: LfsCacheT
    root* {.importc: "root".}: array[2, LfsChunkT]
    mlist* {.importc: "mlist".}: ptr lfs_mlist
    seed* {.importc: "seed".}: uint32
    gstate* {.importc: "gstate".}: LfsGstateT
    gdisk* {.importc: "gdisk".}: LfsGstateT
    gdelta* {.importc: "gdelta".}: LfsGstateT
    free* {.importc: "free".}: lfs_free_lfs_5
    cfg* {.importc: "cfg".}: ptr LfsConfig
    blockCount* {.importc: "block_count".}: LfsSizeT
    nameMax* {.importc: "name_max".}: LfsSizeT
    fileMax* {.importc: "file_max".}: LfsSizeT
    attrMax* {.importc: "attr_max".}: LfsSizeT
    when defined(LFS_MIGRATE):
      lfs1* {.importc: "lfs1", header: "lfs.h".}: ptr Lfs1

iterator openFileObjects*(x: LfsT): ptr lfs_mlist =
  var p: ptr ptr lfs_mlist = addr(x.mlist)
  while not p[].isNil:
    yield p[]
    p = addr((p[]).next)

when not defined(LFS_READONLY):
  proc lfsFormat*(lfs: ptr LfsT; config: ptr LfsConfig): cint {.importc: "lfs_format",
      header: "lfs.h".}

proc lfsMount*(lfs: ptr LfsT; config: ptr LfsConfig): cint {.importc: "lfs_mount",
    header: "lfs.h".}

proc lfsUnmount*(lfs: ptr LfsT): cint {.importc: "lfs_unmount", header: "lfs.h".}

when not defined(LFS_READONLY):
  proc lfsRemove*(lfs: ptr LfsT; path: cstring): cint {.importc: "lfs_remove",
      header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsRename*(lfs: ptr LfsT; oldpath: cstring; newpath: cstring): cint {.
      importc: "lfs_rename", header: "lfs.h".}

proc lfsStat*(lfs: ptr LfsT; path: cstring; info: ptr LfsInfo): cint {.
    importc: "lfs_stat", header: "lfs.h".}

proc lfsGetattr*(lfs: ptr LfsT; path: cstring; `type`: uint8; buffer: pointer;
                size: LfsSizeT): LfsSsizeT {.importc: "lfs_getattr", header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsSetattr*(lfs: ptr LfsT; path: cstring; `type`: uint8; buffer: pointer;
                  size: LfsSizeT): cint {.importc: "lfs_setattr", header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsRemoveattr*(lfs: ptr LfsT; path: cstring; `type`: uint8): cint {.
      importc: "lfs_removeattr", header: "lfs.h".}

when not defined(LFS_NO_MALLOC):
  proc lfsFileOpen*(lfs: ptr LfsT; file: ptr LfsFileT; path: cstring; flags: cint): cint {.
      importc: "lfs_file_open", header: "lfs.h".}

proc lfsFileOpencfg*(lfs: ptr LfsT; file: ptr LfsFileT; path: cstring; flags: cint;
                    config: ptr LfsFileConfig): cint {.importc: "lfs_file_opencfg",
    header: "lfs.h".}

proc lfsFileClose*(lfs: ptr LfsT; file: ptr LfsFileT): cint {.importc: "lfs_file_close",
    header: "lfs.h".}

proc lfsFileSync*(lfs: ptr LfsT; file: ptr LfsFileT): cint {.importc: "lfs_file_sync",
    header: "lfs.h".}

proc lfsFileRead*(lfs: ptr LfsT; file: ptr LfsFileT; buffer: pointer; size: LfsSizeT): LfsSsizeT {.
    importc: "lfs_file_read", header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsFileWrite*(lfs: ptr LfsT; file: ptr LfsFileT; buffer: pointer; size: LfsSizeT): LfsSsizeT {.
      importc: "lfs_file_write", header: "lfs.h".}

proc lfsFileSeek*(lfs: ptr LfsT; file: ptr LfsFileT; off: LfsSoffT; whence: cint): LfsSoffT {.
    importc: "lfs_file_seek", header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsFileTruncate*(lfs: ptr LfsT; file: ptr LfsFileT; size: LfsOffT): cint {.
      importc: "lfs_file_truncate", header: "lfs.h".}

proc lfsFileTell*(lfs: ptr LfsT; file: ptr LfsFileT): LfsSoffT {.
    importc: "lfs_file_tell", header: "lfs.h".}

proc lfsFileRewind*(lfs: ptr LfsT; file: ptr LfsFileT): cint {.
    importc: "lfs_file_rewind", header: "lfs.h".}

proc lfsFileSize*(lfs: ptr LfsT; file: ptr LfsFileT): LfsSoffT {.
    importc: "lfs_file_size", header: "lfs.h".}

when not defined(LFS_READONLY):
  proc lfsMkdir*(lfs: ptr LfsT; path: cstring): cint {.importc: "lfs_mkdir",
      header: "lfs.h".}

proc lfsDirOpen*(lfs: ptr LfsT; dir: ptr LfsDirT; path: cstring): cint {.
    importc: "lfs_dir_open", header: "lfs.h".}

proc lfsDirClose*(lfs: ptr LfsT; dir: ptr LfsDirT): cint {.importc: "lfs_dir_close",
    header: "lfs.h".}

proc lfsDirRead*(lfs: ptr LfsT; dir: ptr LfsDirT; info: ptr LfsInfo): cint {.
    importc: "lfs_dir_read", header: "lfs.h".}

proc lfsDirSeek*(lfs: ptr LfsT; dir: ptr LfsDirT; off: LfsOffT): cint {.
    importc: "lfs_dir_seek", header: "lfs.h".}

proc lfsDirTell*(lfs: ptr LfsT; dir: ptr LfsDirT): LfsSoffT {.importc: "lfs_dir_tell",
    header: "lfs.h".}

proc lfsDirRewind*(lfs: ptr LfsT; dir: ptr LfsDirT): cint {.importc: "lfs_dir_rewind",
    header: "lfs.h".}

proc lfsFsStat*(lfs: ptr LfsT; fsinfo: ptr LfsFsinfo): cint {.importc: "lfs_fs_stat",
    header: "lfs.h".}

proc lfsFsSize*(lfs: ptr LfsT): LfsSsizeT {.importc: "lfs_fs_size", header: "lfs.h".}

proc lfsFsTraverse*(lfs: ptr LfsT; cb: proc (a1: pointer; a2: LfsChunkT): cint;
                   data: pointer): cint {.importc: "lfs_fs_traverse", header: "lfs.h".}

proc lfsFsGc*(lfs: ptr LfsT): cint {.importc: "lfs_fs_gc", header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsFsMkconsistent*(lfs: ptr LfsT): cint {.importc: "lfs_fs_mkconsistent",
      header: "lfs.h".}
when not defined(LFS_READONLY):
  proc lfsFsGrow*(lfs: ptr LfsT; blockCount: LfsSizeT): cint {.importc: "lfs_fs_grow",
      header: "lfs.h".}

