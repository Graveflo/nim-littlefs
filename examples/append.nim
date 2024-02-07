import littlefs/all
import littlefs/configs/file_config

import std/os

const fsPath = "testfs.bin"


proc main()=
  var f = open(fsPath, fmReadWriteExisting)
  var lfs = LittleFs(cfg: makeFileLfsConfig(f))
  lfs.boot()
  
  var textFile = open(lfs, "text_File", fmAppend)
  textFile.writeString("\nThis is a test")
  textFile.sync()
  textFile.close()

when isMainModule:
  main()
