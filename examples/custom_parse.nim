import littlefs/all
import littlefs/configs/file_config

import std/os

type A = object
  f1: int
  f2: pointer
  f3: string

proc readImpl*[T: A](lfs: ptr LfsT, file: ptr LfsFileT, tds: typedesc[T]): T =
  result.f1 = read[int](lfs, file)
  result.f3 = read[string](lfs, file)

proc write*[T: A](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
  result += write(lfs, file, val.f1)
  result += write(lfs, file, val.f3)

const fsPath = "testfs.bin"

var f = open(fsPath, if fileExists(fsPath): fmReadWriteExisting else: fmReadWrite)
var lfs = LittleFs(cfg: makeFileLfsConfig(f, block_count=1024))
lfs.boot()
var file = lfs.open("custom_file", LFS_O_RDWR, LFS_O_CREAT)
file.write("This is a string")
file.write(A(f1: 4, f3: "This is another string"))
file.rewind()
echo read[string](file)
echo read[A](file)
