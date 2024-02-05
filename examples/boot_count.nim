import littlefs/all
import littlefs/configs/file_config

import std/os

const fsPath = "testfs.bin"

var f = open(fsPath, if fileExists(fsPath): fmReadWriteExisting else: fmReadWrite)
var lfs = LittleFs(cfg: makeFileLfsConfig(f, block_count=1024))
lfs.boot()
var file = lfs.open("boot_count", LFS_O_RDWR, LFS_O_CREAT)
var boot_count = read[int](file)
echo "boot count: ", boot_count
inc boot_count
file.rewind()
file.write(boot_count)
