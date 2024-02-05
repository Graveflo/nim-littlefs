import std/macros

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
    var
      flag = true
      i = 0
    while (i < len(x)) and flag:
      flag = flag and (sub[i] == x[i])
      inc i
    if flag: return true
  return false
