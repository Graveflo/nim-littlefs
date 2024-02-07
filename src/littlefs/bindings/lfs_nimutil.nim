import std/[endians, bitops]

proc `-`*[T: SomeUnsignedInt](a: T): T = (high(T) - a) + 1

{. push overflowChecks: off, cdecl, exportc .}

proc lfs_max*(a: uint32; b: uint32): uint32 {.inline.} = max(a, b)

proc lfs_min*(a: uint32; b: uint32): uint32 {.inline.} = min(a, b)

proc lfs_aligndown*(a: uint32; alignment: uint32): uint32 {.inline.} =
  return a - (a mod alignment)

proc lfs_alignup*(a: uint32; alignment: uint32): uint32 {.inline.} =
  # Align to nearest multiple of a size
  return lfs_aligndown(a + alignment - 1, alignment)

proc lfs_npw2*(a: uint32): uint32 {.inline.} =
  # Find the smallest power of 2 greater than or equal to a
  return 32 - countLeadingZeroBits(a - 1).uint32

proc lfs_ctz*(a: uint32): uint32 {.inline.} =
  # Count the number of trailing binary zeros in a
  # lfsCtz(0) may be undefined
  when not defined(lfs_No_Intrinsics) and defined(gnuc):
    return builtinCtz(a)
  else:
    return lfsNpw2((a and -a) + 1) - 1

proc lfs_popc*(a: uint32): uint32 {.inline.} =
  # Count the number of binary ones in a
  return countSetBits(a).uint32

proc lfs_scmp*(a: uint32; b: uint32): cint {.inline.} =
  # Find the sequence comparison of a and b, this is the distance
  # between a and b ignoring overflow
  return cast[cint](a - b)

proc lfs_fromle32*(a: uint32): uint32 {.inline.} =
  # Convert between 32-bit little-endian and native order
  when system.cpuEndian == bigEndian:
    swapEndian32(result.addr, a.addr)
  else:
    a

proc lfs_tole32*(a: uint32): uint32 {.inline.} =
  return lfsFromle32(a)

proc lfs_frombe32*(a: uint32): uint32 {.inline.} =
  # Convert between 32-bit big-endian and native order
  when system.cpuEndian == littleEndian:
    swapEndian32(result.addr, a.addr)
  else:
    a

proc lfs_tobe32*(a: uint32): uint32 {.inline.} =
  return lfsFrombe32(a)

proc lfs_crc*(crci: uint32; buffer: pointer; size: csize_t): uint32 =
  let rtable: array[16, uint32] = [0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
                                0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
                                0xedb88320.uint32, 0xf00f9344.uint32, 0xd6d6a3e8.uint32, 0xcb61b38c.uint32,
                                0x9b64c2b0.uint32, 0x86d3d2d4.uint32, 0xa00ae278.uint32, 0xbdbdf21c.uint32]
  var crc = crci
  let data = cast[ptr UncheckedArray[uint8]](buffer)
  for i in 0..<size:
    crc = (crc shr 4) xor rtable[(crc xor (data[i] shr 0)) and 0xf]
    crc = (crc shr 4) xor rtable[(crc xor (data[i] shr 4)) and 0xf]
  return crc

proc lfs_malloc*(size: csize_t): pointer {.inline.} =
  when not defined(LFS_NO_MALLOC):
    return create(byte, size)
  else:
    cast[nil](size)
    return nil

proc lfs_free*(p: pointer) {.inline.} =
  when not defined(LFS_NO_MALLOC):
    dealloc(p)
  else:
    cast[nil](p)

{. pop .}