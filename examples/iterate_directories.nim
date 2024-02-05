import littlefs/all
import littlefs/configs/file_config

import std/os

const fsPath = "testfs.bin"


proc main()=
  var f = open(fsPath, if fileExists(fsPath): fmReadWriteExisting else: fmReadWrite)
  var lfs = LittleFs(cfg: makeFileLfsConfig(f, block_count=1024))
  lfs.boot()
  
  var textFile: ref LfsFile
  if lfs.fileExists("text_File"):
    textFile = open(lfs, "text_File", fmReadWriteExisting)
  else:
    textFile = open(lfs, "text_File", fmReadWrite)
    textFile.writeString("hello")
    textFile.rewind()
  let s = readAll(textFile)
  echo s
  
  lfs.mkDir("something")
  lfs.mkDir("something/otherthing")
  lfs.mkDir("other_thing")

  for x in lfs.walk("/"):
    echo cast[cstring](x.name.addr)

when isMainModule:
  main()
