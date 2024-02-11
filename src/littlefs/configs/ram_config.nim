import ../api/common
import ../bindings/lfs

import std/os

proc lfsRamRead(c: ptr LfsConfig; chunk: uint32; off: uint32;
                 buffer: pointer; size: uint32): cint {. cdecl .} =
  let src = cast[ptr UncheckedArray[byte]](c.context)
  let dest = cast[ptr UncheckedArray[byte]](buffer)
  let offset = (c.block_size * chunk) + off
  for i in 0..<size:
    dest[i] = src[i + offset]
  return 0

proc lfsRamProgram(c: ptr LfsConfig; chunk: uint32; off: uint32;
                    buffer: pointer; size: uint32): cint {. cdecl .} =
  let src = cast[ptr UncheckedArray[byte]](buffer)
  let dest = cast[ptr UncheckedArray[byte]](c.context)
  let offset = (c.block_size * chunk) + off
  for i in 0..<size:
    dest[i + offset] = src[i]
  return 0

proc lfsRamSync(c: ptr LfsConfig): cint {. cdecl .} = 0

proc lfsRamErase(c: ptr LfsConfig; chunk: LfsChunkT): cint {. cdecl .} =
  let dest = cast[pointer](cast[uint](c.context) + (c.block_size * chunk))
  zeroMem(dest, c.block_size)
  return 0

proc mapRamLfsConfig*(result: var LfsConfig)=
  result.read = lfsRamRead
  result.prog = lfsRamProgram
  result.erase = lfsRamErase
  result.sync = lfsRamSync

proc makeRamLfsConfig*(block_size:range[1..high(int)], block_count: range[1..high(int)],
                       rs=16,ps=8,cs=16,ls=16,bcy=1): LfsConfig =
  var
    bs = block_size
    bc = block_count
  result.mapRamLfsConfig()
  result.context = create(byte, block_size*block_count)
  result.read_size = rs.LfsSizeT
  result.prog_size = ps.LfsSizeT
  result.block_size = bs.uint32
  result.cache_size = cs.LfsSizeT
  result.lookahead_size = ls.LfsSizeT
  result.block_count = bc.LfsSizeT
  result.block_cycles = bcy.int32
