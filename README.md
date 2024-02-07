# littlefs API + bindings for Nim

This is still experimental since I have not tested it or used it at all.

Clone the [littlefs](https://github.com/littlefs-project/littlefs) repository and observe their copyright and distribution license.
Copyright (c) 2022, The littlefs authors.
Copyright (c) 2017, Arm Limited. All rights reserved.

## Boot count example
This example is translated from the littlefs github [README](https://github.com/littlefs-project/littlefs/blob/master/README.md)

```nim
import littlefs/all
import littlefs/configs/file_config

import std/os

const fsPath = "testfs.bin"

var f = open(fsPath, if fileExists(fsPath): fmReadWriteExisting else: fmReadWrite)
var lfs = LittleFs(cfg: makeFileLfsConfig(f, block_count=1024))
lfs.boot()
var file = lfs.open("boot_count", fmReadWrite)
var boot_count = read[int](file)
echo "boot count: ", boot_count
inc boot_count
file.rewind()
file.write(boot_count)
```

## Project directory
```
examples
src
  ---> littlefs
    ---> api                High level API
    ---> bindings           Thin wrapping
      ---> lfs_nimutil.nim  Nim implementation of lfs_util.h
    ---> configs            Modules for premade configs
tests                       Nothing yet
buildsys.nims               Build system will go here if needed
```

## Building with buildsys.nims
This library comes with a Nim implementation of lfs_util.h. To use it define `lfsUseNimUtils`. The build tasks
and the api both observe this definition.

The following will clone littlefs and build it. This task will build two versions of the littlefs C library, 
one of which is compiled expecting the nim implemnation of `lfs_util.h`. Library files will be dropped at
`build/liblfs.a` and `build/liblfsNim.a` respectively:

`nim buildLfsLibs buildsys.nims`

To build the littlefs C source with asserts, errors and warnings disabled:

`nim -d:danger buildLfsLibs buildsys.nims`

To build the fuse driver run:

`nim buildFuse buildsys.nims`

or

`nim -d:lfsUseNimUtils -d:release buildFuse buildsys.nims`

---

You can import "config.nims", or if in nimble path, `littlefs/api/build_help/config.nims` to have the c sources automatically added via `cincludes` and the correct library given the state of
`lfsUseNimUtils`.

The api file `common.nim` will import and export `bindings/lfs_nimutil.nim` when `lfsUseNimUtils` is defined so that it is easy to 
compile with this option enabled

## FYIs
- The destructors are designed to try and clean up before destroying the `LittleFs` object, but this 
is not supported by the littlefs C library as far as I'm aware. I did my best, but I can't gaurentee it will work.
- File objects and Dir objects are heap allocated `ref`s. This is because they must maintain a constant memory address for
littlefs to function properly. It's easy enough to handle them on the stack if you want to, but you might have to use the thin wrappings in `bindings`
to use the API functions as they expect `ref` objects
- Although it may be annoying the error handling mechanism is a global `var LfsErrNo` that you have to manually check. Maybe this will change in future
- This project does not conform to Nim's style guide and I do not intend to. If there are self-contained inconsistencies, then I will fix them
- Atlas will be the target env management program, nimble related things will be maintained at bare minimum
- The default configurations are not exactly sane, just change them to fit your needs. They should probably be explicitly defined anyways

## Future plans
- Configs for nesper (ESP32)
- Maybe more API features as I need them (PRs welcome)
    - Maybe implement user attributes
- Maybe implement exceptions with a `-d:lfsExceptions`
