import ../bindings/lfs

import std/os

proc lfsFileRead(c: ptr LfsConfig; chunk: uint32; off: uint32;
                 buffer: pointer; size: uint32): cint {. cdecl .} =
  var f = cast[File](c.context)
  f.setFilePos(((c.block_size * chunk) + (off*1)).int)
  discard f.readBuffer(buffer, size).cint

proc lfsFileProgram(c: ptr LfsConfig; chunk: uint32; off: uint32;
                    buffer: pointer; size: uint32): cint {. cdecl .} =
  var f = cast[File](c.context)
  f.setFilePos(((c.block_size * chunk) + (off * 1)).int)
  discard f.writeBuffer(buffer, size).cint

proc lfsFileSync(c: ptr LfsConfig): cint {. cdecl .} = 0

proc lfsFileErase(c: ptr LfsConfig; chunk: LfsChunkT): cint {. cdecl .} =
  let f = cast[File](c.context)
  f.setFilePos((c.block_size * chunk).int)
  let buffer = create(byte, c.blockSize)
  discard f.writeBuffer(buffer, c.blockSize).cint
  dealloc(buffer)

proc mapFileLfsConfig*(result: var LfsConfig)=
  result.read = lfsFileRead
  result.prog = lfsFileProgram
  result.erase = lfsFileErase
  result.sync = lfsFileSync

proc makeFileLfsConfig*(f: File, block_count: int, block_size = -1): LfsConfig =
  var bs = block_size
  if block_size == -1:
    let info = f.getFileInfo
    bs = info.blockSize
  result.mapFileLfsConfig()
  result.read_size = 16
  result.prog_size = 8
  result.block_size = bs.uint32
  result.cache_size = 16
  result.lookahead_size = 16
  result.block_count = block_count.LfsSizeT
  result.block_cycles = 1
  result.context = cast[pointer](f)

proc makeFileLfsConfig*(f: File): LfsConfig =
  let info = f.getFileInfo
  if info.blockSize > info.size:
    raise newException(IOError, "The given file is not large enough to facilitate a filesystem")
  return makeFileLfsConfig(f, info.blockSize, info.size div info.blockSize)
