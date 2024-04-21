import system, math, sugar, sequtils, strformat
import core, vars, fau/[fmath, color], pkg/polymorph
import duktape/js
import types, apivars, dukconst, patterns

type JavaScriptError* = object of CatchableError

var
  ctx: DTContext
  callbackId = 0

#region QOL functions

template pushVec2(v: Vec2, writable = true) =
  discard ctx.duk_push_object()
  setObjNumber("x", v.x, writable)
  setObjNumber("y", v.y, writable)

proc getVec2(idx: cint): Vec2 =
  discard ctx.duk_get_prop_string(idx, "x")
  let x = ctx.duk_to_number(-1).float
  discard ctx.duk_get_prop_string(idx, "y")
  let y = ctx.duk_to_number(-1).float
  return vec2(x, y)

template pushColor(c: Color, writable = true) =
  discard ctx.duk_push_object()
  setObjNumber("r", c.r, writable)
  setObjNumber("g", c.g, writable)
  setObjNumber("b", c.b, writable)
  setObjNumber("a", c.a, writable)

proc getColor(idx: cint): Color =
  discard ctx.duk_get_prop_string(idx, "r")
  let r = ctx.duk_get_number(-1).float
  discard ctx.duk_get_prop_string(idx, "g")
  let g = ctx.duk_get_number(-1).float
  discard ctx.duk_get_prop_string(idx, "b")
  let b = ctx.duk_get_number(-1).float
  discard ctx.duk_get_prop_string(idx, "a")
  let a = ctx.duk_get_number(-1).float
  ctx.duk_pop_n(4)
  return rgba(r, g, b, a)

proc getColorDefault(idx: cint, default: Color): Color =
  let invalid = (ctx.duk_get_top() <= idx) or
    (ctx.duk_check_type(idx, DUK_TYPE_OBJECT) != 1) or
    (ctx.duk_get_prop_string(idx, "r") == 0) or
    (ctx.duk_get_prop_string(idx, "g") == 0) or
    (ctx.duk_get_prop_string(idx, "b") == 0) or
    (ctx.duk_get_prop_string(idx, "a") == 0)

  if invalid:
    return default
  
  let r = ctx.duk_get_number(-4).float
  let g = ctx.duk_get_number(-3).float
  let b = ctx.duk_get_number(-2).float
  let a = ctx.duk_get_number(-1).float

  ctx.duk_pop_n(4)
  return rgba(r, g, b, a)

proc getVec2Array(idx: cint): seq[Vec2] =
  ctx.duk_require_object(idx)
  let len = ctx.duk_get_length(idx).int
  result = @[]
  for i in 0..<len:
    discard ctx.duk_get_prop_index(idx, i.cuint)
    result.add(getVec2(-1))
    ctx.duk_pop()

# Property setters
template setObjectProperty(name: string, writable: bool, body: untyped) =
  # Assume object is at the top of the stack
  discard ctx.duk_push_string(name)         # push property name
  body                                      # push property value

  var flags: duk_uint_t =
    DUK_DEFPROP_HAVE_VALUE or               # Modify value
    DUK_DEFPROP_HAVE_WRITABLE or            # Modify writable
    DUK_DEFPROP_FORCE                       # Force property creation

  if writable:
    flags = flags or DUK_DEFPROP_WRITABLE   # Set writable

  ctx.duk_def_prop(-3, flags)               # define property

template setObjInt(name: string, value: int, writable = true) =
  setGlobalProperty(name, writable, ctx.duk_push_int(value.cint))

template setObjNumber(name: string, value: float, writable = true) =
  setObjectProperty(name, writable, ctx.duk_push_number(value))

template setObjString(name: string, value: string, writable = true) =
  setObjectProperty(name, writable, ctx.duk_push_string(value))

template setObjVec2(name: string, value: Vec2, writable = true) =
  setObjectProperty(name, writable, pushVec2(value, writable))

template setObjColor(name: string, value: Color, writable = true) =
  setObjectProperty(name, writable, pushColor(value, writable))

template setObjFunc(name: string, argc: int, f: DTCFunction) =
  setObjectProperty(name, false, (discard ctx.duk_push_c_function(f, argc)))

# Property getters
template getObjInt(idx: int, name: string): int =
  discard ctx.duk_get_prop_string(idx, name)
  return ctx.duk_to_int(-1)

template getObjNumber(idx: int, name: string): float =
  discard ctx.duk_get_prop_string(idx, name)
  return ctx.duk_to_number(-1).float

template getObjString(idx: int, name: string): string =
  discard ctx.duk_get_prop_string(idx, name)
  return ctx.duk_to_string(-1)

# Global property setters
template setGlobalProperty(name: string, writable: bool, body: untyped) =
  ctx.duk_push_global_object()              # push global object
  setObjectProperty(name, writable, body)   # set property
  ctx.duk_pop()                             # pop global object

template setGlobalInt(name: string, value: int, writable = true) =
  setGlobalProperty(name, writable, ctx.duk_push_int(value))

template setGlobalNumber(name: string, value: float, writable = true) =
  setGlobalProperty(name, writable, ctx.duk_push_number(value))

template setGlobalString(name: string, value: string, writable = true) =
  setGlobalProperty(name, writable, ctx.duk_push_string(value))

template setGlobalVec2(name: string, value: Vec2, writable = true) =
  setGlobalProperty(name, writable, pushVec2(value, writable))

template setGlobalColor(name: string, value: Color, writable = true) =
  setGlobalProperty(name, writable, pushColor(value, writable))

template setGlobalVec2iArray(name: string, values: seq[Vec2i], writable = true) =
  var flags: duk_uint_t =
    DUK_DEFPROP_HAVE_VALUE or               # Modify value
    DUK_DEFPROP_HAVE_WRITABLE               # Modify writable
  if writable:
    flags = flags or DUK_DEFPROP_WRITABLE   # Set writable

  ctx.duk_push_global_object()              # push global object
  discard ctx.duk_push_string(name)         # push property name
  let arr_idx = ctx.duk_push_array()        # push array
  
  # Push values
  for i, v in values:
    pushVec2(vec2(v), writable)
    discard ctx.duk_put_prop_index(arr_idx, i.cuint)
  ctx.duk_def_prop(-3, flags)               # define property
  ctx.duk_pop()                             # pop global object

## Pushes a function to the global context
## name: The name of the function
## argc: The number of arguments the function takes (use -1 for varargs)
## f: The function to push
template setGlobalFunc(name: string, argc: int, f: DTCFunction) =
  setGlobalProperty(name, false, (discard ctx.duk_push_c_function(f, argc)))

#endregion

# Loads a script from a string
# Returns whether the script was loaded successfully
proc loadScript*(script: string): bool =
  let err = ctx.duk_peval_string(script)
  return err == 0

proc initJsApi*() =
  # Create heap
  ctx = duk_create_heap_default()

  #region Define classes

  #region Vec2

  # class Vec2
  # constructor(float x = 0, float y = x)
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    let
      x = ctx.duk_get_number_default(0, 0).float
      y = ctx.duk_get_number_default(1, x).float
    pushVec2(vec2(x, y))
    return 1
  ), 2)

  # add(Vec2 u, Vec2 v)
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_require_object(0)
    ctx.duk_require_object(1)
    let
      u = getVec2(0)
      v = getVec2(1)
      res = u + v
    pushVec2(res)
    return 1
  ), 2)
  discard ctx.duk_put_prop_string(-2, "add")

  # sub(Vec2 u, Vec2 v)
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_require_object(0)
    ctx.duk_require_object(1)
    let
      u = getVec2(0)
      v = getVec2(1)
      res = u - v
    pushVec2(res)
    return 1
  ), 2)
  discard ctx.duk_put_prop_string(-2, "sub")

  # neg(Vec2 v)
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_require_object(0)
    let
      v = getVec2(0)
      res = -v
    pushVec2(res)
    return 1
  ), 1)
  discard ctx.duk_put_prop_string(-2, "neg")

  # scale(Vec2 v, float s)
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_require_object(0)
    let
      u = getVec2(0)
      s = ctx.duk_require_number(1).float
      res = u * s
    pushVec2(res)
    return 1
  ), 2)
  discard ctx.duk_put_prop_string(-2, "scale")

  discard ctx.duk_put_global_string("Vec2")

  #endregion
  
  #region Color
  
  # class Color
  # constructor(float r, float g, float b, float a = 1)
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    let
      r = ctx.duk_require_number(0).float
      g = ctx.duk_require_number(1).float
      b = ctx.duk_require_number(2).float
      a = ctx.duk_get_number_default(3, 1).float
      col = rgba(r, g, b, a)
    pushColor(col)
  ), 4)

  # mix(Color a, Color b, float t, string mode = "mix")
  setObjFunc("mix", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_require_object(0)
    ctx.duk_require_object(1)
    let
      a = getColor(0)
      b = getColor(1)
      t = ctx.duk_require_number(2).float
      mode = $ctx.duk_get_string_default(3, "mix")
      res = apiMixColor(a, b, t, mode)
    pushColor(res)
    return 1
  ))

  # parse(hex: string): Color
  setObjFunc("parse", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      hex = $ctx.duk_require_string(0)
      col = parseColor(hex)
    pushColor(col)
    return 1
  ))

  # Static fields
  setObjColor("shadow", rgba(0f, 0f, 0f, 0.4f), false)
  setObjColor("accent", colorAccent, false)
  setObjColor("ui", colorUi, false)
  setObjColor("uiDark", colorUiDark, false)
  setObjColor("hit", colorHit, false)
  setObjColor("heal", colorHeal, false)
  setObjColor("clear", colorClear, false)
  setObjColor("white", colorWhite, false)
  setObjColor("black", colorBlack, false)
  setObjColor("gray", colorGray, false)
  setObjColor("royal", colorRoyal, false)
  setObjColor("coral", colorCoral, false)
  setObjColor("orange", colorOrange, false)
  setObjColor("red", colorRed, false)
  setObjColor("magenta", colorMagenta, false)
  setObjColor("purple", colorPurple, false)
  setObjColor("green", colorGreen, false)
  setObjColor("blue", colorBlue, false)
  setObjColor("pink", colorPink, false)
  setObjColor("yellow", colorYellow, false)

  discard ctx.duk_put_global_string("Color")

  #endregion

  #region Math

  # # class Math
  # ctx.duk_push_global_object()
  # discard ctx.duk_push_string("Math")
  # discard ctx.duk_push_object()

  # # abs(float x): float
  # setObjFunc("abs", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.abs.cdouble)
  #   return 1
  # ))

  # # acos(float x): float
  # setObjFunc("acos", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.arccos.cdouble)
  #   return 1
  # ))

  # # asin(float x): float
  # setObjFunc("asin", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.arcsin.cdouble)
  #   return 1
  # ))

  # # atan(float x): float
  # setObjFunc("atan", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.arctan.cdouble)
  #   return 1
  # ))

  # # atan2(float y, float x): float
  # setObjFunc("atan2", 2, (proc(ctx: DTContext): cint{.stdcall.} =
  #   let
  #     y = ctx.duk_require_number(0).float
  #     x = ctx.duk_require_number(1).float
  #   ctx.duk_push_number(arctan2(y, x))
  #   return 1
  # ))

  # # ceil(float x): float
  # setObjFunc("ceil", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.ceil.cdouble)
  #   return 1
  # ))

  # # cos(float x): float
  # setObjFunc("cos", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.cos.cdouble)
  #   return 1
  # ))

  # # cosh(float x): float
  # setObjFunc("cosh", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.cosh.cdouble)
  #   return 1
  # ))

  # # deg(float x): float
  # setObjFunc("deg", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.deg.cdouble)
  #   return 1
  # ))

  # # exp(float x): float
  # setObjFunc("exp", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.exp.cdouble)
  #   return 1
  # ))

  # # sgn(float x): float
  # setObjFunc("sgn", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.sgn.cdouble)
  #   return 1
  # ))

  # # sqrt(float x): float
  # setObjFunc("sqrt", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.sqrt.cdouble)
  #   return 1
  # ))

  # # fac(int x): int
  # setObjFunc("fac", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_int(ctx.duk_require_int(0).int.fac.cint)
  #   return 1
  # ))

  # # floor(float x): float
  # setObjFunc("floor", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.floor.cdouble)
  #   return 1
  # ))

  # # ln(float x): float
  # setObjFunc("ln", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.ln.cdouble)
  #   return 1
  # ))

  # # log(float x): float
  # setObjFunc("log", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.log10.cdouble)
  #   return 1
  # ))

  # # log2(float x): float
  # setObjFunc("log2", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.log2.cdouble)
  #   return 1
  # ))

  # # max(...args): float
  # setObjFunc("max", -1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   var max = ctx.duk_require_number(0).float
  #   let top = ctx.duk_get_top()
  #   for i in 1..<top:
  #     let x = ctx.duk_require_number(i).float
  #     max = max(max, x)
  #   ctx.duk_push_number(max)
  #   return 1
  # ))

  # # min(...args): float
  # setObjFunc("min", -1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   var min = ctx.duk_require_number(0).float
  #   let top = ctx.duk_get_top()
  #   for i in 1..<top:
  #     let x = ctx.duk_require_number(i).float
  #     min = min(min, x)
  #   ctx.duk_push_number(min)
  #   return 1
  # ))

  # # rad(float x): float
  # setObjFunc("rad", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.rad.cdouble)
  #   return 1
  # ))

  # # pow(float x, float y): float
  # setObjFunc("pow", 2, (proc(ctx: DTContext): cint{.stdcall.} =
  #   let
  #     x = ctx.duk_require_number(0).float
  #     y = ctx.duk_require_number(1).float
  #   ctx.duk_push_number(x.pow(y))
  #   return 1
  # ))

  # # sin(float x): float
  # setObjFunc("sin", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.sin.cdouble)
  #   return 1
  # ))

  # # sinh(float x): float
  # setObjFunc("sinh", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.sinh.cdouble)
  #   return 1
  # ))

  # # tan(float x): float
  # setObjFunc("tan", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.tan.cdouble)
  #   return 1
  # ))

  # # tanh(float x): float
  # setObjFunc("tanh", 1, (proc(ctx: DTContext): cint{.stdcall.} =
  #   ctx.duk_push_number(ctx.duk_require_number(0).float.tanh.cdouble)
  #   return 1
  # ))

  # ctx.duk_def_prop(-3,
  #   DUK_DEFPROP_HAVE_VALUE or
  #   DUK_DEFPROP_HAVE_WRITABLE
  # )

  # ctx.duk_pop()

  #endregion

  #endregion

  #region Global constants
  
  setGlobalVec2("shadowOffset", vec2(0.3), false)
  setGlobalInt("mapSize", mapSize, false)

  setGlobalVec2iArray("d4", d4.toSeq(), false)
  setGlobalVec2iArray("d4mid", d4mid.toSeq(), false)
  setGlobalVec2iArray("d4edge", d4edge.toSeq(), false)
  setGlobalVec2iArray("d8", d8.toSeq(), false)
  setGlobalVec2iArray("d8mid", d8mid.toSeq(), false)

  #endregion

  #region Global objects

  discard ctx.duk_push_object()
  discard ctx.duk_put_global_string("fau")

  discard ctx.duk_push_object()
  discard ctx.duk_put_global_string("state")

  #endregion

  #region Value functions
  
  # px(x: float): int
  setGlobalFunc("px", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_push_number(ctx.duk_require_int(0).int.px.cdouble) # return argv[0].px
    return 1
  ))

  # getScl(base: float = 0.175): Vec2
  setGlobalFunc("getScl", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      base = ctx.duk_get_number_default(0, 0.175).float
      scl = (base + 0.12f * (1f - splashTime).pow(10f)) * fau.cam.size.y / 17f
    pushVec2(vec2(scl))
    return 1
  ))

  # hoverOffset(scl: float = 0.65, offset: float = 0): Vec2
  setGlobalFunc("hoverOffset", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      scl = ctx.duk_get_number_default(0, 0.65).float
      offset = ctx.duk_get_number_default(1, 0).float
      res = vec2(0f, (fau.time + offset).sin(scl, 0.14f) - 0.14f)
    pushVec2(res)
    return 1
  ))

  # beatSpacing(): float
  setGlobalFunc("beatSpacing", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_push_number(1.0 / (state.currentBpm / 60.0))
    return 1
  ))

  #endregion

  #region Pattern functions

  # drawFft(pos: Vec2, radius: float = px(90), length: float = 8, color: Color = colorWhite)
  setGlobalFunc("drawFft", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      radius = ctx.duk_get_number_default(1, px(90)).float
      length = ctx.duk_get_number_default(2, 8).float
      color = getColorDefault(3, colorWhite)
    patFft(pos, radius, length, color)
    return 0
  ))

  # drawTiles()
  setGlobalFunc("drawTiles", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    patTiles()
    return 0
  ))

  # drawTilesFft()
  setGlobalFunc("drawTilesFft", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    patTilesFft()
    return 0
  ))

  # drawTilesSquare(col1: Color = colorWhite, col2: Color = colorBlue)
  setGlobalFunc("drawTilesSquare", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorWhite)
      col2 = getColorDefault(1, colorBlue)
    patTilesSquare(col1, col2)
    return 0
  ))

  # drawBackground(col: Color = colorWhite)
  setGlobalFunc("drawBackground", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
    patBackground(col)
    return 0
  ))

  # drawStripes(col1: Color = colorPink, col2: Color = Color.mix(colorPink, colorWhite, 0.2), angle: float = rad(135))
  setGlobalFunc("drawStripes", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorPink)
      col2 = getColorDefault(1, apiMixColor(colorPink, colorWhite, 0.2))
      angle = ctx.duk_get_number_default(2, rad(135)).float
    patStripes(col1, col2, angle)
    return 0
  ))

  # drawBeatSquare(col: Color = colorPink.mix(colorWhite, 0.7)
  setGlobalFunc("drawBeatSquare", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, apiMixColor(colorPink, colorWhite, 0.7))
    patBeatSquare(col)
    return 0
  ))

  # drawBeatAlt(col: Color)
  setGlobalFunc("drawBeatAlt", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColor(0)
    patBeatAlt(col)
    return 0
  ))

  # drawTriSquare(pos: Vec2, col: Color, len: float, rad: float, offset: float = rad(45), amount: int = 4, sides: int = 3, shapeOffset: float = rad(0))
  setGlobalFunc("drawTriSquare", 8, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      col = getColor(1)
      len = ctx.duk_require_number(2).float
      rad = ctx.duk_require_number(3).float
      offset = ctx.duk_get_number_default(4, rad(45)).float
      amount = ctx.duk_get_int_default(5, 4).int
      sides = ctx.duk_get_int_default(6, 3).int
      shapeOffset = ctx.duk_get_number_default(7, rad(0)).float
    patTriSquare(pos, col, len, rad, offset, amount, sides, shapeOffset)
    return 0
  ))

  # drawSpin(col1: Color, col2: Color, blades: int = 10)
  setGlobalFunc("drawSpin", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColor(0)
      col2 = getColor(1)
      blades = ctx.duk_get_int_default(2, 10).int
    patSpin(col1, col2, blades)
    return 0
  ))

  # drawSpinGradient(pos: Vec2, col1: Color, col2: Color, len: float = 5, blades: int = 10, spacing: int = 2)
  setGlobalFunc("drawSpinGradient", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      col1 = getColor(1)
      col2 = getColor(2)
      len = ctx.duk_get_number_default(3, 5).float
      blades = ctx.duk_get_int_default(4, 10).int
      spacing = ctx.duk_get_int_default(5, 2).int
    patSpinGradient(pos, col1, col2, len, blades, spacing)
    return 0
  ))

  # drawSpinShape(col1: Color, col2: Color, sides: int = 4, rad: float = 2.5, turnSpeed: float = rad(19), rads: int = 6, radsides: int = 4, radOff: float = 7, radrad: float = 1.3, radrotscl: float = 0.25)
  setGlobalFunc("drawSpinShape", 10, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColor(0)
      col2 = getColor(1)
      sides = ctx.duk_get_int_default(2, 4).int
      rad = ctx.duk_get_number_default(3, 2.5).float
      turnSpeed = ctx.duk_get_number_default(4, rad(19)).float
      rads = ctx.duk_get_int_default(5, 6).int
      radsides = ctx.duk_get_int_default(6, 4).int
      radOff = ctx.duk_get_number_default(7, 7).float
      radrad = ctx.duk_get_number_default(8, 1.3).float
      radrotscl = ctx.duk_get_number_default(9, 0.25).float
    patSpinShape(col1, col2, sides, rad, turnSpeed, rads, radsides, radOff, radrad, radrotscl)
    return 0
  ))

  # drawShapeBack(col1: Color, col2: Color, sides: int = 4, spacing: float = 2.5, angle: float = rad(90))
  setGlobalFunc("drawShapeBack", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColor(0)
      col2 = getColor(1)
      sides = ctx.duk_get_int_default(2, 4).int
      spacing = ctx.duk_get_number_default(3, 2.5).float
      angle = ctx.duk_get_number_default(4, rad(90)).float
    patShapeBack(col1, col2, sides, spacing, angle)
    return 0
  ))

  # drawFadeShapes(col: Color)
  setGlobalFunc("drawFadeShapes", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColor(0)
    patFadeShapes(col)
    return 0
  ))

  # drawRain(amount: int = 80)
  setGlobalFunc("drawRain", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      amount = ctx.duk_get_int_default(0, 80).int
    patRain(amount)
    return 0
  ))

  # drawPetals()
  setGlobalFunc("drawPetals", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    patPetals()
    return 0
  ))

  # drawSkats()
  setGlobalFunc("drawSkats", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    patSkats()
    return 0
  ))

  # drawClouds(col: Color = colorWhite)
  setGlobalFunc("drawClouds", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
    patClouds(col)
    return 0
  ))

  # drawLongClouds(col: Color = colorWhite)
  setGlobalFunc("drawLongClouds", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
    patLongClouds(col)
    return 0
  ))

  # drawStars(col: Color = colorWhite, flash: Color = colorWhite, amount: int = 40, seed: int = 1)
  setGlobalFunc("drawStars", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      flash = getColorDefault(1, colorWhite)
      amount = ctx.duk_get_int_default(2, 40).int
      seed = ctx.duk_get_int_default(3, 1).int
    patStars(col, flash, amount, seed)
    return 0
  ))

  # drawTris(col1: Color = colorWhite, col2: Color = colorWhite, amount: int = 50, seed: int = 1)
  setGlobalFunc("drawTris", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorWhite)
      col2 = getColorDefault(1, colorWhite)
      amount = ctx.duk_get_int_default(2, 50).int
      seed = ctx.duk_get_int_default(3, 1).int
    patTris(col1, col2, amount, seed)
    return 0
  ))

  # drawBounceSquares(col: Color = colorWhite)
  setGlobalFunc("drawBounceSquares", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
    patBounceSquares(col)
    return 0
  ))

  # drawCircles(col: Color = colorWhite, time: float = state_time, amount: int = 50, seed: int = 1, minSize: float = 2, maxSize: float = 7, moveSpeed: float = 0.2)
  setGlobalFunc("drawCircles", 7, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      time = ctx.duk_get_number_default(1, state.time).float
      amount = ctx.duk_get_int_default(2, 50).int
      seed = ctx.duk_get_int_default(3, 1).int
      minSize = ctx.duk_get_number_default(4, 2).float32
      maxSize = ctx.duk_get_number_default(5, 7).float32
      moveSpeed = ctx.duk_get_number_default(6, 0.2).float
    patCircles(col, time, amount, seed, minSize..maxSize, moveSpeed)
    return 0
  ))

  # drawRadTris(col: Color = colorWhite, time: float = state_time, amount: int = 50, seed: int = 1)
  setGlobalFunc("drawRadTris", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      time = ctx.duk_get_number_default(1, state.time).float
      amount = ctx.duk_get_int_default(2, 50).int
      seed = ctx.duk_get_int_default(3, 1).int
    patRadTris(col, time, amount, seed)
    return 0
  ))

  # drawMissiles(col: Color = colorWhite, time: float = state_time, amount: int = 50, seed: int = 1)
  setGlobalFunc("drawMissiles", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      time = ctx.duk_get_number_default(1, state.time).float
      amount = ctx.duk_get_int_default(2, 50).int
      seed = ctx.duk_get_int_default(3, 1).int
    patMissiles(col, time, amount, seed)
    return 0
  ))

  # drawFallSquares(col1: Color = colorWhite, col2: Color = colorWhite, time: float = state_time, amount: int = 50)
  setGlobalFunc("drawFallSquares", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorWhite)
      col2 = getColorDefault(1, colorWhite)
      time = ctx.duk_get_number_default(2, state.time).float
      amount = ctx.duk_get_int_default(3, 50).int
    patFallSquares(col1, col2, time, amount)
    return 0
  ))

  # drawFlame(col1: Color = colorWhite, col2: Color = colorWhite, time: float = state_time, amount: int = 80)
  setGlobalFunc("drawFlame", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorWhite)
      col2 = getColorDefault(1, colorWhite)
      time = ctx.duk_get_number_default(2, state.time).float
      amount = ctx.duk_get_int_default(3, 80).int
    patFlame(col1, col2, time, amount)
    return 0
  ))

  # drawSquares(col: Color = colorWhite, time: float = state_time, amount: int = 50, seed: int = 2)
  setGlobalFunc("drawSquares", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      time = ctx.duk_get_number_default(1, state.time).float
      amount = ctx.duk_get_int_default(2, 50).int
      seed = ctx.duk_get_int_default(3, 2).int
    patSquares(col, time, amount, seed)
    return 0
  ))

  # drawRoundLine(pos: Vec2, angle: float, len: float, color: Color = colorWhite, stroke: float = 1)
  setGlobalFunc("drawRoundLine", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      angle = ctx.duk_require_number(1).float
      len = ctx.duk_require_number(2).float
      color = getColorDefault(3, colorWhite)
      stroke = ctx.duk_get_number_default(4, 1).float
    roundLine(pos, angle, len, color, stroke)
    return 0
  ))

  # drawLines(col: Color = colorWhite, seed: int = 1, amount: int = 30, angle: float = rad(45))
  setGlobalFunc("drawLines", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      seed = ctx.duk_get_int_default(1, 1).int
      amount = ctx.duk_get_int_default(2, 30).int
      angle = ctx.duk_get_number_default(3, rad(45)).float
    patLines(col, seed, amount, angle)
    return 0
  ))

  # drawRadLinesRound(col: Color = colorWhite, seed: int = 6, amount: int = 40, stroke: float = 0.25, posScl: float = 1, lenScl: float = 1)
  setGlobalFunc("drawRadLinesRound", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      seed = ctx.duk_get_int_default(1, 6).int
      amount = ctx.duk_get_int_default(2, 40).int
      stroke = ctx.duk_get_number_default(3, 0.25).float
      posScl = ctx.duk_get_number_default(4, 1).float
      lenScl = ctx.duk_get_number_default(5, 1).float
    patRadLines(col, seed, amount, stroke, posScl, lenScl)
    return 0
  ))

  # drawRadCircles(col: Color = colorWhite, seed: int = 7, amount: int = 40, fin: float = 0.5)
  setGlobalFunc("drawRadCircles", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      seed = ctx.duk_get_int_default(1, 7).int
      amount = ctx.duk_get_int_default(2, 40).int
      fin = ctx.duk_get_number_default(3, 0.5).float
    patRadCircles(col, seed, amount, fin)
    return 0
  ))

  # drawSpikes(pos: Vec2, col: Color = colorWhite, amount: int = 10, offset: float = 8, len: float = 3, angleOffset: float = 0)
  setGlobalFunc("drawSpikes", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      col = getColorDefault(1, colorWhite)
      amount = ctx.duk_get_int_default(2, 10).int
      offset = ctx.duk_get_number_default(3, 8).float
      len = ctx.duk_get_number_default(4, 3).float
      angleOffset = ctx.duk_get_number_default(5, 0).float
    patSpikes(pos, col, amount, offset, len, angleOffset)
    return 0
  ))

  # drawGradient(col1: Color = colorClear, col2: Color = colorClear, col3: Color = colorClear, col4: Color = colorClear)
  setGlobalFunc("drawGradient", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorClear)
      col2 = getColorDefault(1, colorClear)
      col3 = getColorDefault(2, colorClear)
      col4 = getColorDefault(3, colorClear)
    patGradient(col1, col2, col3, col4)
    return 0
  ))

  # drawVertGradient(col1: Color = colorClear, col2: Color = colorClear)
  setGlobalFunc("drawVertGradient", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorClear)
      col2 = getColorDefault(1, colorClear)
    patVertGradient(col1, col2)
    return 0
  ))

  # drawZoom(col: Color = colorWhite, offset: float = 0, amount: int = 10, sides: int = 4)
  setGlobalFunc("drawZoom", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColorDefault(0, colorWhite)
      offset = ctx.duk_get_number_default(1, 0).float
      amount = ctx.duk_get_int_default(2, 10).int
      sides = ctx.duk_get_int_default(3, 4).int
    patZoom(col, offset, amount, sides)
    return 0
  ))

  # drawFadeOut(time: float)
  setGlobalFunc("drawFadeOut", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      time = ctx.duk_require_number(0).float
    patFadeOut(time)
    return 0
  ))

  # drawFadeIn(time: float)
  setGlobalFunc("drawFadeIn", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      time = ctx.duk_require_number(0).float
    patFadeIn(time)
    return 0
  ))

  # drawSpace(col: Color)
  setGlobalFunc("drawSpace", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col = getColor(0)
    patSpace(col)
    return 0
  ))

  # drawUnit(pos: Vec2, scl: Vec2 = new Vec2(1, 1), color: Color = colorWhite, part: string = "")
  setGlobalFunc("drawUnit", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      scl = getVec2(1)
      color = getColorDefault(2, colorWhite)
      part = $ctx.duk_get_string_default(3, "")
    currentUnit.getTexture(part).draw(pos, scl = scl, color = color)
    return 0
  ))

  #endregion

  #region Basic drawing functions

  # drawFillQuadGradient(v1: Vec2, v2: Vec2, v3: Vec2, v4: Vec2, c1: Color, c2: Color, c3: Color, c4: Color, z: float = 0)
  setGlobalFunc("drawFillQuadGradient", 9, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      v1 = getVec2(0)
      v2 = getVec2(1)
      v3 = getVec2(2)
      v4 = getVec2(3)
      c1 = getColor(4)
      c2 = getColor(5)
      c3 = getColor(6)
      c4 = getColor(7)
      z = ctx.duk_get_number_default(8, 0).float
    fillQuad(v1, c1, v2, c2, v3, c3, v4, c4, z)
    return 0
  ))

  # drawFillQuad(v1: Vec2, v2: Vec2, v3: Vec2, v4: Vec2, color: Color, z: float = 0)
  setGlobalFunc("drawFillQuad", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      v1 = getVec2(0)
      v2 = getVec2(1)
      v3 = getVec2(2)
      v4 = getVec2(3)
      color = getColor(4)
      z = ctx.duk_get_number_default(5, 0).float
    fillQuad(v1, v2, v3, v4, color, z)
    return 0
  ))

  # drawFillRect(x: float, y: float, w: float, h: float, color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawFillRect", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      x = ctx.duk_require_number(0).float
      y = ctx.duk_require_number(1).float
      w = ctx.duk_require_number(2).float
      h = ctx.duk_require_number(3).float
      color = getColorDefault(4, colorWhite)
      z = ctx.duk_get_number_default(5, 0).float
    fillRect(x, y, w, h, color, z)
    return 0
  ))

  # drawFillSquare(pos: Vec2, radius: float, color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawFillSquare", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      radius = ctx.duk_require_number(1).float
      color = getColorDefault(2, colorWhite)
      z = ctx.duk_get_number_default(3, 0).float
    fillSquare(pos, radius, color, z)
    return 0
  ))

  # drawFillTri(v1: Vec2, v2: Vec2, v3: Vec2, color: Color, z: float = 0)
  setGlobalFunc("drawFillTri", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      v1 = getVec2(0)
      v2 = getVec2(1)
      v3 = getVec2(2)
      color = getColor(3)
      z = ctx.duk_get_number_default(4, 0).float
    fillTri(v1, v2, v3, color, z)
    return 0
  ))

  # drawFillTriGradient(v1: Vec2, v2: Vec2, v3: Vec2, c1: Color, c2: Color, c3: Color, z: float = 0)
  setGlobalFunc("drawFillTriGradient", 7, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      v1 = getVec2(0)
      v2 = getVec2(1)
      v3 = getVec2(2)
      c1 = getColor(3)
      c2 = getColor(4)
      c3 = getColor(5)
      z = ctx.duk_get_number_default(6, 0).float
    fillTri(v1, v2, v3, c1, c2, c3, z)
    return 0
  ))

  # drawFillCircle(pos: Vec2, rad: float, color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawFillCircle", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      rad = ctx.duk_require_number(1).float
      color = getColorDefault(2, colorWhite)
      z = ctx.duk_get_number_default(3, 0).float
    fillCircle(pos, rad, color, z)
    return 0
  ))

  # drawFillPoly(pos: Vec2, sides: int, radius: float, rotation: float = 0, color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawFillPoly", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sides = ctx.duk_require_int(1).int
      radius = ctx.duk_require_number(2).float
      rotation = ctx.duk_get_number_default(3, 0).float
      color = getColorDefault(4, colorWhite)
      z = ctx.duk_get_number_default(5, 0).float
    fillPoly(pos, sides, radius, rotation, color, z)
    return 0
  ))

  # drawFillLight(pos: Vec2, radius: float, sides: int, centerColor: Color = colorWhite, edgeColor: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawFillLight", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      radius = ctx.duk_require_number(1).float
      sides = ctx.duk_require_int(2).int
      centerColor = getColorDefault(3, colorWhite)
      edgeColor = getColorDefault(4, colorWhite)
      z = ctx.duk_get_number_default(5, 0).float
    fillLight(pos, radius, sides, centerColor, edgeColor, z)
    return 0
  ))

  # drawLine(p1: Vec2, p2: Vec2, stroke: float = px(1), color: Color = colorWhite, square: bool = true, z: float = 0)
  setGlobalFunc("drawLine", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      p1 = getVec2(0)
      p2 = getVec2(1)
      stroke = ctx.duk_get_number_default(2, px(1)).float
      color = getColorDefault(3, colorWhite)
      square = ctx.duk_get_boolean_default(4, 1) == 1
      z = ctx.duk_get_number_default(5, 0).float
    line(p1, p2, stroke, color, square, z)
    return 0
  ))

  # drawLineAngle(p: Vec2, angle: float, len: float, stroke: float = px(1), color: Color = colorWhite, square: bool = true, z: float = 0)
  setGlobalFunc("drawLineAngle", 7, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      p = getVec2(0)
      angle = ctx.duk_require_number(1).float
      len = ctx.duk_require_number(2).float
      stroke = ctx.duk_get_number_default(3, px(1)).float
      color = getColorDefault(4, colorWhite)
      square = ctx.duk_get_boolean_default(5, 1) == 1
      z = ctx.duk_get_number_default(6, 0).float
    lineAngle(p, angle, len, stroke, color, square, z)
    return 0
  ))

  # drawLineAngleCenter(p: Vec2, angle: float, len: float, stroke: float = px(1), color: Color = colorWhite, square: bool = true, z: float = 0)
  setGlobalFunc("drawLineAngleCenter", 7, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      p = getVec2(0)
      angle = ctx.duk_require_number(1).float
      len = ctx.duk_require_number(2).float
      stroke = ctx.duk_get_number_default(3, px(1)).float
      color = getColorDefault(4, colorWhite)
      square = ctx.duk_get_boolean_default(5, 1) == 1
      z = ctx.duk_get_number_default(6, 0).float
    lineAngleCenter(p, angle, len, stroke, color, square, z)
    return 0
  ))

  # drawLineRect(pos: Vec2, size: Vec2, stroke: float = px(1), color: Color = colorWhite, z: float = 0, margin: float = 0)
  setGlobalFunc("drawLineRect", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      size = getVec2(1)
      stroke = ctx.duk_get_number_default(2, px(1)).float
      color = getColorDefault(3, colorWhite)
      z = ctx.duk_get_number_default(4, 0).float
      margin = ctx.duk_get_number_default(5, 0).float
    lineRect(pos, size, stroke, color, z, margin)
    return 0
  ))

  # drawLineSquare(pos: Vec2, rad: float, stroke: float = px(1), color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawLineSquare", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      rad = ctx.duk_require_number(1).float
      stroke = ctx.duk_get_number_default(2, px(1)).float
      color = getColorDefault(3, colorWhite)
      z = ctx.duk_get_number_default(4, 0).float
    lineSquare(pos, rad, stroke, color, z)
    return 0
  ))

  # drawRadLines(pos: Vec2, sides: int, radius: float, len: float, stroke: float = px(1), rotation: float = 0, color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawRadLines", 8, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sides = ctx.duk_require_int(1).int
      radius = ctx.duk_require_number(2).float
      len = ctx.duk_require_number(3).float
      stroke = ctx.duk_get_number_default(4, px(1)).float
      rotation = ctx.duk_get_number_default(5, 0).float
      color = getColorDefault(6, colorWhite)
      z = ctx.duk_get_number_default(7, 0).float
    spikes(pos, sides, radius, len, stroke, rotation, color, z)
    return 0
  ))

  # drawPoly(pos: Vec2, sides: int, radius: float, rotation: float = 0, stroke: float = px(1), color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawPoly", 7, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sides = ctx.duk_require_int(1).int
      radius = ctx.duk_require_number(2).float
      rotation = ctx.duk_get_number_default(3, 0).float
      stroke = ctx.duk_get_number_default(4, px(1)).float
      color = getColorDefault(5, colorWhite)
      z = ctx.duk_get_number_default(6, 0).float
    poly(pos, sides, radius, rotation, stroke, color, z)
    return 0
  ))

  # drawArcRadius(pos: Vec2, sides: int, angleFrom: float, angleTo: float, radiusFrom: float, radiusTo: float, rotation: float = 0, color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawArcRadius", 9, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sides = ctx.duk_require_int(1).int
      angleFrom = ctx.duk_require_number(2).float
      angleTo = ctx.duk_require_number(3).float
      radiusFrom = ctx.duk_require_number(4).float
      radiusTo = ctx.duk_require_number(5).float
      rotation = ctx.duk_get_number_default(6, 0).float
      color = getColorDefault(7, colorWhite)
      z = ctx.duk_get_number_default(8, 0).float
    arcRadius(pos, sides, angleFrom, angleTo, radiusFrom, radiusTo, rotation, color, z)
    return 0
  ))

  # drawArc(pos: Vec2, sides: int, angleFrom: float, angleTo: float, radius: float, rotation: float = 0, stroke: float = px(1), color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawArc", 9, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sides = ctx.duk_require_int(1).int
      angleFrom = ctx.duk_require_number(2).float
      angleTo = ctx.duk_require_number(3).float
      radius = ctx.duk_require_number(4).float
      rotation = ctx.duk_get_number_default(5, 0).float
      stroke = ctx.duk_get_number_default(6, px(1)).float
      color = getColorDefault(7, colorWhite)
      z = ctx.duk_get_number_default(8, 0).float
    arc(pos, sides, angleFrom, angleTo, radius, rotation, stroke, color, z)
    return 0
  ))

  # drawCrescent(pos: Vec2, sides: int, angleFrom: float, angleTo: float, radius: float, rotation: float = 0, stroke: float = px(1), color: Color = colorWhite, z: float = 0)
  setGlobalFunc("drawCrescent", 9, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sides = ctx.duk_require_int(1).int
      angleFrom = ctx.duk_require_number(2).float
      angleTo = ctx.duk_require_number(3).float
      radius = ctx.duk_require_number(4).float
      rotation = ctx.duk_get_number_default(5, 0).float
      stroke = ctx.duk_get_number_default(6, px(1)).float
      color = getColorDefault(7, colorWhite)
      z = ctx.duk_get_number_default(8, 0).float
    crescent(pos, sides, angleFrom, angleTo, radius, rotation, stroke, color, z)
    return 0
  ))

  # drawShape(points: Array, wrap: bool = false, stroke: float = px(1), color: Color = colorWhite, z: float = 0)
  # TODO test this
  setGlobalFunc("drawShape", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      points = getVec2Array(0)
      wrap = ctx.duk_get_boolean_default(1, 0) == 1
      stroke = ctx.duk_get_number_default(2, px(1)).float
      color = getColorDefault(3, colorWhite)
      z = ctx.duk_get_number_default(4, 0).float
    poly(points, wrap, stroke, color, z)
    return 0
  ))

  #endregion

  #region Special drawing functions

  # beginBloom()
  setGlobalFunc("beginBloom", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    drawBloomA()
    return 0
  ))

  # endBloom()
  setGlobalFunc("endBloom", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    drawBloomB()
    return 0
  ))

  #endregion

  #region Abilities

  # makeWall(pos: Vec2, sprite: string = "wall", life: int = 10, health: int = 3)
  setGlobalFunc("makeWall", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      sprite = $ctx.duk_get_string_default(1, "wall")
      life = ctx.duk_get_int_default(2, 10).int
      health = ctx.duk_get_int_default(3, 3).int
    apiMakeWall(vec2i(pos), sprite, life, health)
    return 0
  ))

  # damageBlocks(pos: Vec2)
  setGlobalFunc("damageBlocks", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
    apiDamageBlocks(vec2i(pos.x.int, pos.y.int))
    return 0
  ))

  #endregion

  #region Makers

  # makeDelay(delay: int, callback: function())
  # TODO test this
  setGlobalFunc("makeDelay", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      delay = ctx.duk_require_int(0).int
    ctx.duk_require_function(1)
    
    # Save the callback to the global stash
    ctx.duk_push_global_stash()
    ctx.duk_dup(1)
    discard ctx.duk_put_prop_string(-2, (&"cb{callbackId}").cstring)
    
    capture callbackId:
      apiMakeDelay(delay, (proc() =
        ctx.duk_push_global_stash()
        discard ctx.duk_get_prop_string(-1, (&"cb{callbackId}").cstring)

        let err = ctx.duk_pcall(0)
        if err != 0:
          echo "Error in makeDelay callback:"
          echo ctx.duk_safe_to_string(-1)

        # Delete callback from stash
        discard ctx.duk_del_prop_string(-2, (&"cb{callbackId}").cstring)
        ctx.duk_pop_2()
      ))
    
    callbackId.inc()
    return 0
  ))

  # makeBullet(pos: Vec2, dir: Vec2, tex: string = "bullet")
  setGlobalFunc("makeBullet", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
      tex = $ctx.duk_get_string_default(2, "bullet")
    apiMakeBullet(vec2i(pos), vec2i(dir), tex)
    return 0
  ))

  # makeTimedBullet(pos: Vec2, dir: Vec2, tex: string = "bullet", life: int = 3)
  setGlobalFunc("makeTimedBullet", 4, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
      tex = $ctx.duk_get_string_default(2, "bullet")
      life = ctx.duk_get_int_default(3, 3).int
    apiMakeTimedBullet(vec2i(pos), vec2i(dir), tex, life)
    return 0
  ))

  # makeConveyor(pos: Vec2, dir: Vec2, length: int = 2, tex: string = "conveyor", gen: int = 0)
  setGlobalFunc("makeConveyor", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
      length = ctx.duk_get_int_default(2, 2).int
      tex = $ctx.duk_get_string_default(3, "conveyor")
      gen = ctx.duk_get_int_default(4, 0).int
    apiMakeConveyor(vec2i(pos), vec2i(dir), length, tex, gen)
    return 0
  ))

  # makeLaserSegment(pos: Vec2, dir: Vec2)
  setGlobalFunc("makeLaserSegment", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
    apiMakeLaserSegment(vec2i(pos), vec2i(dir))
    return 0
  ))

  # makeRouter(pos: Vec2, length: int = 2, life: int = 2, diag: bool = false, tex: string = "router", allDir: bool = false)
  setGlobalFunc("makeRouter", 6, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      length = ctx.duk_get_int_default(1, 2).int
      life = ctx.duk_get_int_default(2, 2).int
      diag = ctx.duk_get_boolean_default(3, 0) == 1
      tex = $ctx.duk_get_string_default(4, "router")
      allDir = ctx.duk_get_boolean_default(5, 0) == 1
    apiMakeRouter(vec2i(pos), length, life, diag, tex, allDir)
    return 0
  ))

  # makeSorter(pos: Vec2, mdir: Vec2, moveSpace: int = 2, spawnSpace: int = 2, length: int = 1)
  setGlobalFunc("makeSorter", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      mdir = getVec2(1)
      moveSpace = ctx.duk_get_int_default(2, 2).int
      spawnSpace = ctx.duk_get_int_default(3, 2).int
      length = ctx.duk_get_int_default(4, 1).int
    apiMakeSorter(vec2i(pos), vec2i(mdir), moveSpace, spawnSpace, length)
    return 0
  ))

  # makeTurret(pos: Vec2, face: Vec2, reload: int = 4, life: int = 8, tex: string = "duo")
  setGlobalFunc("makeTurret", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      face = getVec2(1)
      reload = ctx.duk_get_int_default(2, 4).int
      life = ctx.duk_get_int_default(3, 8).int
      tex = $ctx.duk_get_string_default(4, "duo")
    apiMakeTurret(vec2i(pos), vec2i(face), reload, life, tex)
    return 0
  ))

  # makeArc(pos: Vec2, dir: Vec2, tex: string = "arc", bounces: int = 1, life: int = 3)
  setGlobalFunc("makeArc", 5, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
      tex = $ctx.duk_get_string_default(2, "arc")
      bounces = ctx.duk_get_int_default(3, 1).int
      life = ctx.duk_get_int_default(4, 3).int
    apiMakeArc(vec2i(pos), vec2i(dir), tex, bounces, life)
    return 0
  ))

  # makeDelayBullet(pos: Vec2, dir: Vec2, tex: string = "")
  setGlobalFunc("makeDelayBullet", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
      tex = $ctx.duk_get_string_default(2, "")
    apiMakeDelayBullet(vec2i(pos), vec2i(dir), tex)
    return 0
  ))

  # makeDelayBulletWarn(pos: Vec2, dir: Vec2, tex: string = "")
  setGlobalFunc("makeDelayBulletWarn", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
      tex = $ctx.duk_get_string_default(2, "")
    apiMakeDelayBulletWarn(vec2i(pos), vec2i(dir), tex)
    return 0
  ))

  # makeBulletCircle(pos: Vec2, tex: string = "")
  setGlobalFunc("makeBulletCircle", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      tex = $ctx.duk_get_string_default(1, "")
    apiMakeBulletCircle(vec2i(pos), tex)
    return 0
  ))

  # makeLaser(pos: Vec2, dir: Vec2)
  setGlobalFunc("makeLaser", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      dir = getVec2(1)
    apiMakeLaser(vec2i(pos), vec2i(dir))
    return 0
  ))

  #endregion

  #region Effects

  # effectExplode(pos: Vec2)
  setGlobalFunc("effectExplode", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
    apiEffectExplode(pos)
    return 0
  ))

  # effectExplodeHeal(pos: Vec2)
  setGlobalFunc("effectExplodeHeal", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
    apiEffectExplodeHeal(pos)
    return 0
  ))

  # effectWarn(pos: Vec2, life: float)
  setGlobalFunc("effectWarn", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      life = ctx.duk_require_number(1).float
    apiEffectWarn(pos, life)
    return 0
  ))

  # effectWarnBullet(pos: Vec2, life: float, rotation: float)
  setGlobalFunc("effectWarnBullet", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      life = ctx.duk_require_number(1).float
      rotation = ctx.duk_require_number(2).float
    apiEffectWarnBullet(pos, life, rotation)
    return 0
  ))

  # effectStrikeWave(pos: Vec2, life: float, rotation: float)
  setGlobalFunc("effectStrikeWave", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
      life = ctx.duk_require_number(1).float
      rotation = ctx.duk_require_number(2).float
    apiEffectStrikeWave(pos, life, rotation)
    return 0
  ))

  #endregion

  #region Other functions

  # changeBpm(bpm: float)
  setGlobalFunc("changeBpm", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      bpm = ctx.duk_require_number(0).float

    state.currentBpm = bpm
    let
      baseTime = 60.0 / state.map.bpm
      curTime = 60.0 / state.currentBpm
      baseTurn = state.secs / baseTime
    state.turnOffset = (baseTime - curTime) * baseTurn / curTime + baseTurn - state.turn

    return 0
  ))

  # log(message: string)
  setGlobalFunc("log", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    echo $ctx.duk_safe_to_string(0)
    return 0
  ))

  #endregion

proc updateJs*() =
  discard ctx.duk_get_global_string("fau")
  setObjNumber("time", fau.time, false)
  ctx.duk_pop()

  # Set state
  discard ctx.duk_get_global_string("state")
  setObjNumber("secs",       state.secs,            false)
  setObjNumber("lastSecs",   state.lastSecs,        false)
  setObjNumber("time",       state.time,            false)
  setObjNumber("rawBeat",    state.rawBeat,         false)
  setObjNumber("moveBeat",   state.moveBeat,        false)
  setObjNumber("hitTime",    state.hitTime,         false)
  setObjNumber("healTime",   state.healTime,        false)
  setObjInt(   "points",     state.points,          false)
  setObjInt(   "turn",       state.turn,            false)
  setObjInt(   "hits",       state.hits,            false)
  setObjInt(   "totalHits",  state.totalHits,       false)
  setObjInt(   "misses",     state.misses,          false)
  setObjNumber("currentBpm", state.currentBpm,      false)
  setObjVec2(  "playerPos",  vec2(state.playerPos), false)
  ctx.duk_pop()


proc addNamespace*(name: string) =
  discard ctx.duk_push_object()
  discard ctx.duk_put_global_string(name)

proc getScriptJs*(namespace, name: string): (proc()) =
  capture name:
    return (proc() =
      updateJs()

      # Get function
      discard ctx.duk_get_global_string(namespace)      # get namespace
      discard ctx.duk_get_prop_string(-1, name)         # get function
      if ctx.duk_check_type(-1, DUK_TYPE_OBJECT) != 1:  # verify that it is a function
        echo "Error in script ", namespace, ".", name, ":"
        echo "Function not found"
        ctx.duk_pop_2()                                 # pop namespace and function
        return
      ctx.duk_dup(-2)                                   # duplicate namespace as this

      # Call function
      let err = ctx.duk_pcall_method(0)                 # call function
      if err != 0:
        echo "Error in script ", namespace, ".", name, ":"
        echo ctx.duk_safe_to_string(-1)
      
      # Pop namespace and return value
      # TODO Test if this fails
      ctx.duk_pop_2()
    )

proc getUnitDrawJs*(namespace, name: string): (proc(unit: Unit, basePos: Vec2)) =
  capture name:
    return (proc(unit: Unit, basePos: Vec2) =
      updateJs()

      currentUnit = unit

      # Get function
      discard ctx.duk_get_global_string(namespace)
      discard ctx.duk_get_prop_string(-1, name)
      if ctx.duk_check_type(-1, DUK_TYPE_OBJECT) != 1:
        echo "Error in script ", namespace, ".", name, ":"
        echo "Function not found"
        ctx.duk_pop_2()
        return
      ctx.duk_dup(-2)

      # Push arguments
      pushVec2(basePos)

      # Call function
      let err = ctx.duk_pcall_method(1)
      if err != 0:
        echo "Error in script ", namespace, ".", name, ":"
        echo ctx.duk_safe_to_string(-1)

      # Pop namespace and return value
      ctx.duk_pop_2()
    )

proc getUnitAbilityJs*(namespace, name: string): (proc(entity: EntityRef, moves: int)) =
  capture name:
    return (proc(entity: EntityRef, moves: int) =
      updateJs()

      let
        gridPosition = fetchGridPosition(entity)
        lastMove = fetchLastMove(entity)
      currentEntityRef = entity

      # Get function
      discard ctx.duk_get_global_string(namespace)
      discard ctx.duk_get_prop_string(-1, name)
      ctx.duk_require_function(-1)
      ctx.duk_dup(-2)

      # Push arguments
      ctx.duk_push_int(moves.cint)
      pushVec2(vec2(gridPosition))
      pushVec2(vec2(lastMove))

      # Call function
      let err = ctx.duk_pcall_method(3)
      if err != 0:
        echo "Error in script ", namespace, ".", name, ":"
        echo ctx.duk_safe_to_string(-1)

      # Pop namespace and return value
      ctx.duk_pop_2()
    )

proc evalScriptJs*(script: string) =
  let err = ctx.duk_peval_string(script)
  if err != 0:
    raise newException(JavaScriptError, $ctx.duk_safe_to_string(-1))
