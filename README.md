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
var lfs = LittleFs(cfg: makeFileLfsConfig(f, 1024))
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

## Building littlefs and linking
Build littlefs as normal with `make build` but take note of the generated files `lfs.o` and `liblfs.a`. If you want to use
the Nim implementation of `lfs_util.h` make sure you compile littlefs with the custom header in `build/lfs_util.h`. You can
do this manually or with the environment variable mentioned in littlefs's `lfs_util.h` file.

If you are using the Nim implementation of `lfs_util.h` and have compiled littlefs as above, then link with `lfs.o` *not* `liblfs.a` and
also `import littlefs/api/lfs_nimutil`:

`--passL:/path/to/lfs.o --cincludes:"path/to/littlefs"`

If you are not using the Nim implementation of `lfs_util.h` then do not do the above and just link to `liblfs.a` as normal:

`--passL:/path/to/liblfs.a --cincludes:"path/to/littlefs"`

## FYIs
- The destructors are designed to try and clean up before destroying the `LittleFs` object, but this 
is not supported by the littlefs C library as far as I'm aware. I did my best, but I can't gaurentee it will work.
- File objects and Dir objects are heap allocated `ref`s. This is because they must maintain a constant memory address for
littlefs to function properly. It's easy enough to handle them on the stack if you want to, but you might have to enable co-variance
to use the API functions as they expect `ref` objects
- Although it may be annoying the error handling mechanism is a global `var LfsErrNo` that you have to manually check. Maybe this will change in future
- This project does not conform to Nim's style guide and I do not intend to. If there are self-contained inconsistencies, then I will fix them
- Atlas will be the target env management program, nimble related things will be maintained at bare minimum

## Future plans
- Configs for nesper (ESP32)
- FUSE implementation
- Maybe more API features as I need them (PRs welcome)
    - Maybe implement user attributes
- Maybe implement exceptions with a `-d:lfsExceptions`
