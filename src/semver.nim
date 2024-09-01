import sequtils, strutils, sugar

type SemVer* = object
  major*, minor*, patch*: int

proc isSemVer*(s: string): bool =
  let parts = s.split(".")
  return parts.len >= 1 and parts.len <= 3 and parts.all(p => p.all(c => c.isDigit))

proc newSemVer*(major = 1, minor = 0, patch = 0): SemVer =
  return SemVer(major: major, minor: minor, patch: patch)

proc newSemVer*(s: string, default = ""): SemVer =
  if not isSemVer(s):
    if not isSemVer(default):
      raise newException(ValueError, "Default version is invalid")
    return newSemVer(default)

  let
    parts = s.split(".")
  return SemVer(
    major: parts[0].parseInt(),
    minor: if parts.len > 1: parts[1].parseInt() else: 0,
    patch: if parts.len > 2: parts[2].parseInt() else: 0
  )

proc `==`*(a, b: SemVer): bool =
  return
    a.major == b.major and
    a.minor == b.minor and
    a.patch == b.patch

proc `!=`*(a, b: SemVer): bool =
  return
    a.major != b.major or
    a.minor != b.minor or
    a.patch != b.patch

proc `<=`*(a, b: SemVer): bool =
  return
    a.major < b.major or
    (a.major == b.major and a.minor < b.minor) or
    (a.major == b.major and a.minor == b.minor and a.patch <= b.patch)

proc `>=`*(a, b: SemVer): bool =
  return
    a.major > b.major or
    (a.major == b.major and a.minor > b.minor) or
    (a.major == b.major and a.minor == b.minor and a.patch >= b.patch)

proc `<`*(a, b: SemVer): bool =
  return
    a.major < b.major or
    (a.major == b.major and a.minor < b.minor) or
    (a.major == b.major and a.minor == b.minor and a.patch < b.patch)

proc `>`*(a, b: SemVer): bool =
  return
    a.major > b.major or
    (a.major == b.major and a.minor > b.minor) or
    (a.major == b.major and a.minor == b.minor and a.patch > b.patch)

proc `$`*(v: SemVer): string =
  return $v.major & "." & $v.minor & "." & $v.patch
