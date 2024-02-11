import std/macros

type
  InvString* = string | cstring
  OpenArrayLike* = concept x
    toOpenArray(x, 0, len(x)) is openArray
  CharArrayLike* = concept x
    toOpenArray(x, 0, len(x)) is openArray[char]

macro importCConst*(tn: typedesc, header_file: string, names: untyped) =
  names.expectKind(nnkStmtList)
  var resultStmtLet = newTree(nnkLetSection)
  
  let itt: NimNode = if names[0].kind in {nnkLetSection, nnkConstSection}:
    names[0]
  else:
    names
  
  if itt.isNil: error("unsupported statement kind")
  for child in itt:
    var sname: NimNode
    case child.kind
    of nnkIdent:
      sname = child
    of nnkAsgn:
      sname = child[0]
    of nnkConstDef:
      if child[0].kind in {nnkPostfix}:
        sname = child[0][1]
      else:
        sname = child[0]
    else:
      error("Unexpected node kind for declaration(" & $child.kind & "): " & repr(child))
    resultStmtLet.add (quote do:
      let `sname.strVal`* {.importc, header: `header_file`, nodecl.}: `tn`)[0]
  resultStmtLet

proc contains*[N;M;T](sol: array[N, array[M,T]], sub: openArray[T]): bool=
  for x in sol:
    result = true
    var i = 0
    while (i < len(x)) and result:
      result = result and sub[i] == x[i]
      inc i
    if result: return

template toOpenArray*(s: OpenArrayLike): untyped =
  toOpenArray(s, 0, s.len-1)

template `|=`*(a: untyped, b: SomeInteger): untyped=
  `a` = a or typeof(a)(b)
