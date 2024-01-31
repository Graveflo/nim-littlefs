{. push importc, nodecl, header: "lfs_util.h" .}

proc lfs_max*(a: uint32; b: uint32): uint32

proc lfs_min*(a: uint32; b: uint32): uint32

proc lfs_aligndown*(a: uint32; alignment: uint32): uint32

proc lfs_alignup*(a: uint32; alignment: uint32): uint32

proc lfs_npw2*(a: uint32): uint32

proc lfs_ctz*(a: uint32): uint32

proc lfs_popc*(a: uint32): uint32

proc lfs_scmp*(a: uint32; b: uint32): cint

proc lfs_fromle32*(a: uint32): uint32

proc lfs_tole32*(a: uint32): uint32

proc lfs_frombe32*(a: uint32): uint32

proc lfs_tobe32*(a: uint32): uint32

proc lfs_crc*(crc: uint32; buffer: pointer; size: csize_t): uint32

proc lfs_malloc*(size: csize_t): pointer

proc lfs_free*(p: pointer)

{. pop .}