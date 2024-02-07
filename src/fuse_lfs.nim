#[
  Heavily inspired by: https://github.com/littlefs-project/littlefs-fuse
]#
import std/[posix, os]
import std/macros
import cligen

import littlefs/api/all
import littlefs/configs/file_config
import littlefs/misc

const FUSE_USE_VERSION {. define .} = 0
when (not defined(nimcheck)) and FUSE_USE_VERSION  < 1:
  {. error: "must supply FUSE_USE_VERSION" .}

type
  ReturnCode = enum
    OK = 0, MountPoint, InputContainer
  cssize_t* {. importc: "ssize_t" .} = int
  FuseBufFlags* = distinct cint
  FuseBufCopyFlags* = distinct cint
  FuseFillDirFlags* = distinct cint
  FuseReadDirFlags* = distinct cint
  FuseCap* = cuint
  FuseConnInfo* {.importc: "struct fuse_conn_info", header: "<fuse.h>", bycopy.} = object
    proto_major* {.importc: "proto_major".}: cuint
    proto_minor* {.importc: "proto_minor".}: cuint
    max_write* {.importc: "max_write".}: cuint
    max_read* {.importc: "max_read".}: cuint
    max_readahead* {.importc: "max_readahead".}: cuint
    capable* {.importc: "capable".}: cuint
    want* {.importc: "want".}: cuint
    max_background* {.importc: "max_background".}: cuint
    congestion_threshold* {.importc: "congestion_threshold".}: cuint
    time_gran* {.importc: "time_gran".}: cuint
    reserved* {.importc: "reserved".}: array[22, cuint]
  FuseFileInfo* {. importc: "struct fuse_file_info", header:"<fuse.h>", nodecl .} = object
    flags* {.importc: "flags".}: cint
    writepage* {.importc: "writepage", bitsize: 1.}: cuint
    direct_io* {.importc: "direct_io", bitsize: 1.}: cuint
    keep_cache* {.importc: "keep_cache", bitsize: 1.}: cuint
    parallel_direct_writes* {.importc: "parallel_direct_writes", bitsize: 1.}: cuint
    flush* {.importc: "flush", bitsize: 1.}: cuint
    nonseekable* {.importc: "nonseekable", bitsize: 1.}: cuint
    flock_release* {.importc: "flock_release", bitsize: 1.}: cuint
    cache_readdir* {.importc: "cache_readdir", bitsize: 1.}: cuint
    noflush* {.importc: "noflush", bitsize: 1.}: cuint
    padding* {.importc: "padding", bitsize: 23.}: cuint
    padding2* {.importc: "padding2", bitsize: 32.}: cuint
    fh* {.importc: "fh".}: uint64
    lock_owner* {.importc: "lock_owner".}: uint64
    poll_events* {.importc: "poll_events".}: uint32
  
  FusePollhandle* {. importc: "struct fuse_pollhandle", header:"<fuse.h>", nodecl .} = object
  FuseSession* {. importc: "fuse_session", header:"<fuse.h>", nodecl .} = object
  FuseConnInfoOpts* {. importc: "fuse_conn_info_opts", header:"<fuse.h>", nodecl .} = object
  
  FuseBuf* {.importc: "struct fuse_buf", header: "<fuse.h>", bycopy.} = object
    size* {.importc: "size".}: csize_t
    flags* {.importc: "flags".}: FuseBufFlags
    mem* {.importc: "mem".}: pointer
    fd* {.importc: "fd".}: cint
    pos* {.importc: "pos".}: Off
  FuseBufVec* {.importc: "struct fuse_bufvec", header: "<fuse.h>", bycopy.} = object
    count* {.importc: "count".}: csize_t
    idx* {.importc: "idx".}: csize_t
    off* {.importc: "off".}: csize_t
    buf* {.importc: "buf".}: array[1, FuseBuf]
  
  fuse_fill_dir_t* = proc (buf: pointer; name: cstring; stbuf: ptr Stat; off: Off;
                        flags: FuseFillDirFlags): cint {. cdecl, gcsafe .}

  FuseConfig* {.importc: "struct fuse_config", header: "<fuse.h>", bycopy.} = object
    set_gid* {.importc: "set_gid".}: cint
    gid* {.importc: "gid".}: cuint
    set_uid* {.importc: "set_uid".}: cint
    uid* {.importc: "uid".}: cuint
    set_mode* {.importc: "set_mode".}: cint
    umask* {.importc: "umask".}: cuint
    entry_timeout* {.importc: "entry_timeout".}: cdouble
    negative_timeout* {.importc: "negative_timeout".}: cdouble
    attr_timeout* {.importc: "attr_timeout".}: cdouble
    intr* {.importc: "intr".}: cint
    intr_signal* {.importc: "intr_signal".}: cint
    remember* {.importc: "remember".}: cint
    hard_remove* {.importc: "hard_remove".}: cint
    use_ino* {.importc: "use_ino".}: cint
    readdir_ino* {.importc: "readdir_ino".}: cint
    direct_io* {.importc: "direct_io".}: cint
    kernel_cache* {.importc: "kernel_cache".}: cint
    auto_cache* {.importc: "auto_cache".}: cint
    no_rofd_flush* {.importc: "no_rofd_flush".}: cint
    ac_attr_timeout_set* {.importc: "ac_attr_timeout_set".}: cint
    ac_attr_timeout* {.importc: "ac_attr_timeout".}: cdouble
    nullpath_ok* {.importc: "nullpath_ok".}: cint
    parallel_direct_writes* {.importc: "parallel_direct_writes".}: cint
    show_help* {.importc: "show_help".}: cint
    modules* {.importc: "modules".}: cstring
    debug* {.importc: "debug".}: cint
  FuseOperations* {. importc: "struct fuse_operations", header:"<fuse.h>", bycopy .} = object
    getattr* {. importc .}: proc(path:cstring, s: ptr Stat, fi: ptr FuseFileInfo): cint {. cdecl, gcsafe .}
    readlink* {. importc .}: proc (path: cstring; output: cstring; size: csize_t): cint {. cdecl, gcSafe  .}
    mknod* {.importc.}: proc (path: cstring; mode: Mode; device: Dev): cint {. cdecl, gcSafe  .}
    mkdir* {.importc.}: proc (path: cstring; mode: Mode): cint {. cdecl, gcSafe  .}
    unlink* {.importc.}: proc (path: cstring): cint {. cdecl, gcSafe  .}
    rmdir* {.importc.}: proc (path: cstring): cint {. cdecl, gcSafe  .}
    symlink* {.importc.}: proc (path: cstring; target: cstring): cint {. cdecl, gcSafe  .}
    rename* {.importc.}: proc (path: cstring; name: cstring; flags: cuint): cint {. cdecl, gcSafe  .}
    link* {.importc.}: proc (path: cstring; target: cstring): cint {. cdecl, gcSafe  .}
    chmod* {.importc.}: proc (path: cstring; mode: Mode; fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    chown* {.importc.}: proc (path: cstring; uid: Uid; gid: Gid; fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    truncate* {.importc.}: proc(path:cstring, offset: posix.Off, fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    open* {.importc.}: proc(path:cstring, fi: ptr FuseFileInfo): cint {. cdecl .}
    read* {.importc.}: proc(path:cstring, buffer: pointer, size: csize_t, offset: posix.Off, fi: ptr FuseFileInfo): cint {.  cdecl, gcSafe  .}
    write* {.importc.}: proc(path:cstring, buffer: pointer, size: csize_t, offset: posix.Off, fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    statfs* {.importc.}: proc (path: cstring; s: ptr Statvfs): cint {. cdecl, gcSafe  .}
    flush* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    release* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    fsync* {.importc.}: proc (path: cstring; a2: cint; fi: ptr FuseFileInfo): cint {. cdecl, gcSafe  .}
    setxattr* {.importc.}: proc (path: cstring; name: cstring; value: cstring; size: csize_t; flags: cint): cint {. cdecl, gcSafe  .}
    getxattr* {.importc.}: proc (path: cstring; name: cstring; value: cstring; size: csize_t): cint {. cdecl, gcSafe  .}
    listxattr* {.importc.}: proc (path: cstring; a2: cstring; a3: csize_t): cint {. cdecl, gcSafe  .}
    removexattr* {.importc.}: proc (path: cstring; name: cstring): cint {. cdecl .}
    opendir* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo): cint {. cdecl .}
    readdir* {.importc.}: proc (path: cstring; p: pointer; fill_dir_proc: fuse_fill_dir_t; offset: Off; fi: ptr FuseFileInfo;
                    flags: FuseReadDirFlags): cint {. cdecl .}
    releasedir* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo): cint {. cdecl .}
    fsyncdir* {.importc.}: proc (path: cstring; a2: cint; fi: ptr FuseFileInfo): cint {. cdecl .}
    init* {.importc.}: proc (conn: ptr FuseConnInfo; cfg: ptr FuseConfig): pointer {. cdecl .}
    destroy* {.importc.}: proc (private_data: pointer) {. cdecl .}
    access* {.importc.}: proc (path: cstring; a2: cint): cint {. cdecl .}
    create* {.importc.}: proc (path: cstring; mode: Mode; fi: ptr FuseFileInfo): cint {. cdecl .}
    lock* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo; cmd: cint; a4: ptr Tflock): cint {. cdecl .}
    utimens* {.importc.}: proc (path: cstring; tv: array[2, Timespec]; fi: ptr FuseFileInfo): cint {. cdecl .}
    bmap* {.importc.}: proc (path: cstring; blocksize: csize_t; idx: ptr uint64): cint {. cdecl .}
    when FUSE_USE_VERSION < 35:
      ioctl* {.importc.}: proc (path: cstring; cmd: cint; p: pointer; fi: ptr FuseFileInfo; flags: cuint; data: pointer): cint {. cdecl .}
    else:
      ioctl* {.importc.}: proc (path: cstring; cmd: cuint; p: pointer; fi: ptr FuseFileInfo; flags: cuint; data: pointer): cint {. cdecl .}
    poll* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo; ph: ptr FusePollhandle; reventsp: ptr cuint): cint {. cdecl .}
    write_buf* {.importc.}: proc (path: cstring; buf: ptr FuseBufvec; offset: Off; fi: ptr FuseFileInfo): cint {. cdecl .}
    read_buf* {.importc.}: proc (path: cstring; bufp: ptr ptr FuseBufvec; size: csize_t; off: Off; fi: ptr FuseFileInfo): cint {. cdecl .}
    flock* {.importc.}: proc (path: cstring; fi: ptr FuseFileInfo; op: cint): cint {. cdecl .}
    fallocate* {.importc.}: proc (path: cstring; a2: cint; a3: Off; a4: Off; fi: ptr FuseFileInfo): cint {. cdecl .}
    copy_file_range* {.importc.}: proc (path_in: cstring; fi_in: ptr FuseFileInfo; offset_in: Off; path_out: cstring;
                            fi_out: ptr FuseFileInfo; offset_out: Off; size: csize_t; flags: cint): cssize_t {. cdecl .}
    lseek* {.importc.}: proc (path: cstring; offset: Off; whence: cint; fi: ptr FuseFileInfo): Off {. cdecl .}

importCConst FuseBufFlags, "<fuse.h>":
  FUSE_BUF_IS_FD          = (1 << 1)
  FUSE_BUF_FD_SEEK        = (1 << 2)
  FUSE_BUF_FD_RETRY       = (1 << 3)

importCConst FuseBufCopyFlags, "<fuse.h>":
  FUSE_BUF_NO_SPLICE      = (1 << 1)
  FUSE_BUF_FORCE_SPLICE   = (1 << 2)
  FUSE_BUF_SPLICE_MOVE    = (1 << 3)
  FUSE_BUF_SPLICE_NONBLOCK= (1 << 4)

importCConst FuseReadDirFlags, "<fuse.h>":
  FUSE_READDIR_PLUS = (1 << 0)

importCConst FuseFillDirFlags, "<fuse.h>":
  FUSE_FILL_DIR_PLUS = (1 << 1)

importCConst FuseCap, "<fuse.h>":
  FUSE_CAP_ASYNC_READ           =  (1 << 0)
  FUSE_CAP_POSIX_LOCKS          =  (1 << 1)
  FUSE_CAP_ATOMIC_O_TRUNC       =  (1 << 3)
  FUSE_CAP_EXPORT_SUPPORT       =  (1 << 4)
  #FUSE_CAP_BIG_WRITES          =  (1 << 5)
  FUSE_CAP_DONT_MASK            =  (1 << 6)
  FUSE_CAP_SPLICE_WRITE         =  (1 << 7)
  FUSE_CAP_SPLICE_MOVE          =  (1 << 8)
  FUSE_CAP_SPLICE_READ          =  (1 << 9)
  FUSE_CAP_FLOCK_LOCKS          =  (1 << 10)
  FUSE_CAP_IOCTL_DIR            =  (1 << 11)
  FUSE_CAP_AUTO_INVAL_DATA      =  (1 << 12)
  FUSE_CAP_READDIRPLUS          =  (1 << 13)
  FUSE_CAP_READDIRPLUS_AUTO     =  (1 << 14)
  FUSE_CAP_ASYNC_DIO            =  (1 << 15)
  FUSE_CAP_WRITEBACK_CACHE      =  (1 << 16)
  FUSE_CAP_NO_OPEN_SUPPORT      =  (1 << 17)
  FUSE_CAP_PARALLEL_DIROPS      =  (1 << 18)
  FUSE_CAP_POSIX_ACL            =  (1 << 19)
  FUSE_CAP_HANDLE_KILLPRIV      =  (1 << 20)
  FUSE_CAP_CACHE_SYMLINKS       =  (1 << 23)
  FUSE_CAP_NO_OPENDIR_SUPPORT   =  (1 << 24)
  FUSE_CAP_EXPLICIT_INVAL_DATA  =  (1 << 25)
  FUSE_CAP_EXPIRE_ONLY          =  (1 << 26)
  FUSE_CAP_SETXATTR_EXT         =  (1 << 27)

var lfs: LittleFs

template TRACE(msg: varargs[string])=
  when defined(debug):
    echo msg

proc lfsFuseInit(conn: ptr FuseConnInfo; cfg: ptr FuseConfig): pointer {. cdecl .} =
  TRACE("lfsFuseInit")
  conn.want |= FUSE_CAP_ATOMIC_O_TRUNC
  #conn.want |= FUSE_CAP_BIG_WRITES

proc lfsFuseDestroy(private_data: pointer) {. cdecl .} =
  TRACE: "destroy?"
  #lfs = LittleFs()

proc lfsFuseStatFs(path: cstring; s: ptr Statvfs): cint {. cdecl .} =
  TRACE: "lfsFuseStatFs"
  zeroMem(s, sizeof(Statvfs))
  let info = lfs.stat()
  if LfsErrNo != LFS_ERR_OK: return LfsErrNo.cint
  let fsSize = lfs.size()
  if fsSize < 0: return fsSize.cint
  s.f_bsize = lfs.cfg.block_size;
  s.f_frsize = lfs.cfg.block_size;
  s.f_blocks = lfs.cfg.block_count;
  s.f_bfree = lfs.cfg.block_count.uint - fsSize.uint;
  s.f_bavail = lfs.cfg.block_count.uint - fsSize.uint;
  s.f_namemax = info.name_max;

proc lfsToStat(info: LfsInfo, result:ptr Stat)=
  TRACE: "lfsToStat"
  zeroMem(result, sizeof(Stat))
  result.st_size = info.size.Off
  result.st_nlink = 1
  result.st_uid = getuid()
  result.st_gid = getgid()
  result.st_blksize = lfs.cfg.blockSize.Blksize
  result.st_blocks = (info.size div lfs.cfg.blockSize).Blkcnt
  when StatHasNanoseconds:
    var nilTime: Timespec
    result.st_atim = nilTime
    result.st_mtim = nilTime
    result.st_ctim = nilTime
  else:
    var nilTime: Time
    result.st_atime = nilTime
    result.st_mtime = nilTime
    result.st_ctime = nilTime
  
  result.st_mode = (S_IRWXU or S_IRWXG or S_IRWXO).Mode
  result.st_mode |= (if info.kind == LFS_TYPE_DIR:
                      S_IFDIR
                    elif info.kind == LFS_TYPE_REG:
                      S_IFREG
                    else:
                      0
                    )

proc lfsFuseGetattr(path:cstring, s: ptr Stat, fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE "lfsFuseGetattr: ", $path
  let info = lfs.stat(path)
  if LfsErrNo != LFS_ERR_OK: return LfsErrNo.cint
  lfsToStat(info, s)

proc lfsFuseAccess(path: cstring; a2: cint): cint {. cdecl .} =
  TRACE: "lfsFuseAccess"
  discard lfs.stat(path)
  return LfsErrNo.cint

proc lfsFuseMkDir(path: cstring; mode: Mode): cint {. cdecl .} =
  TRACE: "lfsFuseMkDir"
  return lfs.mkDir(path).cint

proc lfsFuseOpenDir(path: cstring; fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseOpenDir"
  let dir = lfs.dirOpen(path)
  if LfsErrNo.int < 0: return LfsErrNo.cint
  GC_ref(dir)
  fi.fh = cast[uint64](dir)

proc lfsReleaseDir(path: cstring; fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsReleaseDir"
  if fi.fh != 0:
    let dir = cast[ref LfsDir](fi.fh)
    return dirClose(dir).cint

proc lfsReadDir(path: cstring; p: pointer; fill_dir_proc: fuse_fill_dir_t; offset: Off; fi: ptr FuseFileInfo;
                    flags: FuseReadDirFlags): cint {. cdecl .} =
  TRACE: "lfsReadDir"
  let dir = cast[ref LfsDir](fi.fh)
  GC_ref(dir)
  for info in dir.contents:
    var stat: Stat
    lfsToStat(info, stat.addr)
    discard fill_dir_proc(p, cast[cstring](info.name.addr), stat.addr, offset, 0.FuseFillDirFlags)
  
proc lfsFuseRename(path: cstring; name: cstring; flags: cuint): cint {. cdecl .} =
  TRACE: "lfsFuseRename"
  lfs.rename(path, name).cint

proc lfsFuseUnlink(path: cstring): cint {. cdecl .} =
  TRACE: "lfsFuseUnlink"
  lfs.remove(path).cint

proc convFlagsToOpen(flags: cint): cint =
  if (flags and O_RDONLY) == O_RDONLY:
    result |= LfsOpenFlags.LFS_O_RDONLY.cint
  if (flags and O_WRONLY) == O_WRONLY:
    result |= LfsOpenFlags.LFS_O_WRONLY.cint
  if (flags and O_RDWR) == O_RDWR:
    result |= LfsOpenFlags.LFS_O_RDWR.cint
  if (flags and O_CREAT) == O_CREAT:
    result |= LfsOpenFlags.LFS_O_CREAT.cint
  if (flags and O_EXCL) == O_EXCL:
    result |= LfsOpenFlags.LFS_O_EXCL.cint
  if (flags and O_TRUNC) == O_TRUNC:
    result |= LfsOpenFlags.LFS_O_TRUNC.cint
  if (flags and O_APPEND) == O_APPEND:
    result |= LfsOpenFlags.LFS_O_APPEND.cint
  
proc lfsFuseOpen(path:cstring, fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseOpen"
  let file = lfs.open(path, convFlagsToOpen(fi.flags))
  if LfsErrNo.int < 0: return LfsErrNo.cint
  GC_ref(file)
  fi.fh = cast[uint64](file)

proc lfsFuseRelease(path: cstring; fi: ptr FuseFileInfo): cint {. cdecl .}=
  TRACE "lfsFuseRelease: ", $fi.fh
  if fi.fh != 0:
    let file = cast[ref LfsFile](fi.fh)
    return file.close().cint

proc lfsFuseRead(path:cstring, buffer: pointer, size: csize_t, offset: posix.Off, fi: ptr FuseFileInfo): cint {. cdecl .}=
  TRACE: "lfsFuseRead"
  if fi.fh == 0: return -1
  let file = cast[ref LfsFile](fi.fh)
  GC_ref(file)
  if file.tell != offset:
    if file.seek(offset, LFS_SEEK_SET) < 0:
      return LfsErrNo.cint
  return file.readRaw(buffer, size.int).cint

proc lfsFuseWrite*(path: cstring; buffer: pointer; size: csize_t; offset: Off;
                fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseWrite"
  if fi.fh == 0: return -1
  let file = cast[ref LfsFile](fi.fh)
  GC_ref(file)
  if file.tell != offset:
    if file.seek(offset, LFS_SEEK_SET) < 0:
      return LfsErrNo.cint
  return file.writeRaw(buffer, size.int).cint

proc lfsFuseFsync(path: cstring; a2: cint; fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseFsync"
  if fi.fh == 0: return -1
  let file = cast[ref LfsFile](fi.fh)
  GC_ref(file)
  file.sync()

proc lfsFuseTruncate(path:cstring, offset: posix.Off, fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseTruncate"
  var file: ref LfsFile
  if fi.fh == 0:
    file = lfs.open(path, LfsOpenFlags.LFS_O_WRONLY.cint)
    defer:
      file.close()
  else:
    file = cast[ref LfsFile](fi.fh)
    GC_ref(file)
  file.truncate(offset)
  return LfsErrNo.cint

proc lfsFuseFlush(path: cstring; fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseFlush"
  lfsFuseFSync(path, 0, fi)

proc lfsFuseCreate(path: cstring; mode: Mode; fi: ptr FuseFileInfo): cint {. cdecl .} =
  TRACE: "lfsFuseCreate"
  let err = lfsFuseOpen(path, fi)
  if err < 0:
    return err
  return lfsFuseFsync(path, 0, fi)

proc lfsFuseLink(path: cstring; target: cstring): cint {. cdecl .} = -EPERM
proc lfsFuseMknod(path: cstring; mode: Mode; device: Dev): cint {. cdecl .} = -EPERM
proc lfsFuseChmod(path: cstring; mode: Mode; fi: ptr FuseFileInfo): cint {. cdecl .}= -EPERM
proc lfsFuseChown(path: cstring; uid: Uid; gid: Gid; fi: ptr FuseFileInfo): cint {. cdecl .} = -EPERM
proc lfsFuseUtimens(path: cstring; tv: array[2, Timespec]; fi: ptr FuseFileInfo): cint {. cdecl .} = 0

# TODO: check missing method
# TODO: dir iteration does not include `.` and `..`
# TODO: ??? idk why it is not getting past getattr

proc makeFuseOp(): FuseOperations=
  result = FuseOperations()
  result.getattr = lfsFuseGetattr
  result.access = lfsFuseAccess
  result.truncate = lfsFuseTruncate
  result.open = lfsFuseOpen
  result.read = lfsFuseRead
  result.write = lfsFuseWrite
  result.fsync =lfsFuseFsync
  result.release =lfsFuseRelease
  result.unlink =lfsFuseUnlink
  result.rename = lfsFuseRename
  result.readdir = lfsReadDir
  result.releasedir = lfsReleaseDir
  result.opendir = lfsFuseOpenDir
  result.mkdir = lfsFuseMkDir
  result.statfs = lfsFuseStatFs
  result.destroy = lfsFuseDestroy
  result.init = lfsFuseInit
  result.flush = lfsFuseFlush
  result.create = lfsFuseCreate
  result.link = lfsFuseLink
  
  result.chmod = lfsFuseChmod
  result.chown = lfsFuseChown
  result.utimens = lfsFuseUtimens
  result.mknod = lfsFuseMknod

const lfsFuseOperations = FuseOperations(
    getattr: lfsFuseGetattr,
    access: lfsFuseAccess,
    truncate: lfsFuseTruncate,
    open: lfsFuseOpen,
    read: lfsFuseRead,
    write: lfsFuseWrite,
    fsync: lfsFuseFsync,
    release: lfsFuseRelease,
    unlink: lfsFuseUnlink,
    rename: lfsFuseRename,
    readdir: lfsReadDir,
    releasedir: lfsReleaseDir,
    opendir: lfsFuseOpenDir,
    mkdir: lfsFuseMkDir,
    statfs: lfsFuseStatFs,
    destroy: lfsFuseDestroy,
    init: lfsFuseInit,
    flush: lfsFuseFlush,
    create: lfsFuseCreate,
    link: lfsFuseLink,
    
    chmod: lfsFuseChmod,
    chown: lfsFuseChown,
    utimens:lfsFuseUtimens,
    mknod: lfsFuseMknod
)

proc fuse_main(argc: cint, argv: cStringArray, opers: ptr FuseOperations, data: pointer):
               cint {. importc, header:"<fuse.h>", nodecl .}

proc m():seq[string] = @[]

proc main(mount_file, mp: string, prs: seq[string], rs=16, ps=8, cs=16, lhs=16, bcy=1,
          bs = -1, bc = 0, fuse_args: seq[string]=m()): int=
  if not fileExists(mount_file):
    echo "Input file must exist. Generation coming later"
    return 1
  if not dirExists(mp):
    echo "Mount point does not exist"
    return 1
  let file = open(mount_file, fmReadWriteExisting)
  lfs = LittleFs()
  lfs.cfg = makeFileLfsConfig(file, rs=rs, ps=ps, cs=cs, ls=lhs, bcy=bcy, 
                              block_size=bs, block_count=bc)
  if lfs.mount() != LFS_ERR_OK:
    echo "Failed to mount LFS: ", LfsErrNo.int
    return 1
  var args = @[mount_file.cstring, mp.cstring, "-s".cstring]
  for a in fuse_args: args.add a.cstring
  result = fuse_main(args.len.cint, cast[cStringArray](args[0].addr), lfsFuseOperations.addr, nil)
  if result < 0:
    echo "fuse error: ", result
  echo "exit: ", result

#var cmdLine {.importc: "cmdLine".}: cstringArray
when isMainModule:
  dispatch main, help={
    "mount_file": "Input block device that houses the littlefs",
    "mp": "Path of mount point",
    "rs": "read_size",
    "ps": "prog_size",
    "cs": "cache_size",
    "lhs": "lookahead_size",
    "bcy": "block_cycles",
    "bs": "block_size",
    "bc": "block_count"
  }, short={
    "fuse_args": 'o',
    "mount_file": 'f',
    "mp": 'm'
  }
