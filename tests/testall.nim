import std/[unittest, typetraits, macros]

import littlefs/api/all
import littlefs/configs/ram_config

proc getTyOrDef(s: NimNode): seq[NimNode]=
  let st = s.getType
  expectKind(st, nnkBracketExpr)
  expectKind(st[0], nnkSym)
  expectKind(st[1], nnkBracketExpr)
  for i in st[1]:
    if i.kind == nnkBracketExpr:
      discard  # this is for off branch. What do? maybe fail if not tyOr
    elif i.kind == nnkSym:
      if i.strVal != "or":
        result.add i

proc replaceAll(body, name, wth: NimNode) =  # Elegant, but not beefy
  for i, x in body:
    if x.kind == nnkIdent and name.eqIdent x:
      body[i] = wth
    else:
      x.replaceAll(name, wth)

macro si(typeD: typed, symb: untyped, body:untyped)=
  result = newStmtList()
  for x in typeD.getTyOrDef:
    var bcopy = body.copy()
    replaceAll(bcopy, symb, ident(x.strVal))
    result.add bcopy
  return result

suite "read/write":
  setup:
    var lfs = LittleFs(cfg: makeRamLfsConfig(4096, 1024))
    lfs.boot(force_format=true)
  
  teardown:
    dealloc(lfs.cfg.context)
  
  test "read/write: basic int":
    var file = lfs.open("new_file", fmReadWrite)
    si(SomeInteger, thisType):
      file.write(high(thisType))
    si(SomeInteger, thisType):
      file.write(low(thisType))
    file.close()
    file = lfs.open("new_file", fmReadWrite)
    si(SomeInteger, thisType):
      check read[thisType](file) == high(thisType)
    si(SomeInteger, thisType):
      check read[thisType](file) == low(thisType)

  test "read/write: string":
    var file = lfs.open("some_file", fmReadWrite)
    var one = newString(sizeof(int))
    when system.cpuEndian == bigEndian:
      one[^1] = char(1)
    else:
      one[0] = char(1)
    let uss = one & "this is an unsized string"
    file.writeString(uss)
    file.write("this is a string")
    file.write("another string".toOpenArray)
    file.write(['t','e','s','t'])
    file.rewind()
    check read[string](file) != uss
    file.rewind()
    check file.readString(len(uss)) == uss
    check read[string](file) == "this is a string"
    check read[string](file) == "another string"
    check read[string](file) == "test"
  
  test "read/write: readAll":
    var file = lfs.open("some_file", fmReadWrite)
    let st = """
  ## Deprecated: Setting the environment variable `NIMTEST_COLOR` to `always`
  ## or `never` changes the default for the non-js target to true or false respectively.
  ## Deprecated: the environment variable `NIMTEST_NO_COLOR`, when set, changes the
  ## default to true, if `NIMTEST_COLOR` is undefined.
  ## Set the verbosity of test results.
  ## Default is `PRINT_ALL`, or override with:
  ## `-d:nimUnittestOutputLevel:PRINT_ALL|PRINT_FAILURES|PRINT_NONE`.
    """
    file.writeString(st)
    file.rewind()
    check file.readAll() == st

  test "read/write custom":
    type A = object
      f1: int
      f2: pointer
      f3: string

    proc readImpl[T: A](lfs: ptr LfsT, file: ptr LfsFileT, tds: typedesc[T]): T =
      result.f1 = read[int](lfs, file)
      result.f3 = read[string](lfs, file)

    proc write[T: A](lfs: ptr LfsT, file: ptr LfsFileT, val: T): int {. discardable .} =
      result += write(lfs, file, val.f1)
      result += write(lfs, file, val.f3)
    
    var file = lfs.open("custom_file", LFS_O_RDWR, LFS_O_CREAT)
    file.write(A(f1: 4, f3: "This is a string"))
    file.sync()
    file.rewind()
    check read[A](file) == A(f1: 4, f3: "This is a string")
