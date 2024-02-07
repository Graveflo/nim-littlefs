import ../api/common
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

proc mapFileLfsConfig*(result: var LfsConfig, f: File)=
  mapFileLfsConfig(result)
  result.context = f

proc makeFileLfsConfig*(f: File, rs=16,ps=8,cs=16,ls=16,bcy=1, block_count = 0, block_size = -1): LfsConfig =
  var
    bs = block_size
    bc = block_count
  if block_size < 0:
    bs = f.getFileInfo.blockSize
  result.mapFileLfsConfig(f)
  result.read_size = rs.LfsSizeT
  result.prog_size = ps.LfsSizeT
  result.block_size = bs.uint32
  result.cache_size = cs.LfsSizeT
  result.lookahead_size = ls.LfsSizeT
  result.block_count = bc.LfsSizeT
  result.block_cycles = bcy.int32
