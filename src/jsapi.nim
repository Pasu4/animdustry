import math, sugar, sequtils
import core, vars, fau/[fmath, color], pkg/polymorph
import duktape/js
import types, apivars, dukconst

var
  ctx: DTContext

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
  let r = ctx.duk_to_number(-1).float
  discard ctx.duk_get_prop_string(idx, "g")
  let g = ctx.duk_to_number(-1).float
  discard ctx.duk_get_prop_string(idx, "b")
  let b = ctx.duk_to_number(-1).float
  discard ctx.duk_get_prop_string(idx, "a")
  let a = ctx.duk_to_number(-1).float
  return rgba(r, g, b, a)

# Property setters
template setObjectProperty(name: string, writable: bool, body: untyped) =
  # Assume object is at the top of the stack
  discard ctx.duk_push_string(name)         # push property name
  body                                      # push property value

  var flags: duk_uint_t =
    DUK_DEFPROP_HAVE_VALUE or               # Modify value
    DUK_DEFPROP_HAVE_WRITABLE               # Modify writable

  if writable:
    flags = flags or DUK_DEFPROP_WRITABLE   # Set writable

  discard ctx.duk_put_prop_string(-3, name)         # define property

template setObjInt(name: string, value: int, writable = true) =
  setObjectProperty(name, writable, ctx.duk_push_int(value))

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
template objGetInt(idx: int, name: string): int =
  discard ctx.duk_get_prop_string(idx, name)
  return ctx.duk_to_int(-1)

template objGetNumber(idx: int, name: string): float =
  discard ctx.duk_get_prop_string(idx, name)
  return ctx.duk_to_number(-1).float

template objGetString(idx: int, name: string): string =
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
  let arr_idx = ctx.duk_push_array()
  for i, v in values:
    pushVec2(vec2(v), writable)
    discard ctx.duk_put_prop_index(arr_idx, i.cuint)

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

  #region Define data types

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
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
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
  ), 4)
  discard ctx.duk_put_prop_string(-2, "mix")

  # parse(hex: string): Color
  discard ctx.duk_push_c_function((proc(ctx: DTContext): cint{.stdcall.} =
    let
      hex = $ctx.duk_require_string(0)
      col = parseColor(hex)
    pushColor(col)
    return 1
  ), 1)
  discard ctx.duk_put_prop_string(-2, "parse")

  # Static fields
  pushColor(rgba(0f, 0f, 0f, 0.4f))
  discard ctx.duk_put_prop_string(-2, "shadowColor")
  pushColor(colorAccent)
  discard ctx.duk_put_prop_string(-2, "colorAccent")
  pushColor(colorUi)
  discard ctx.duk_put_prop_string(-2, "colorUi")
  pushColor(colorUiDark)
  discard ctx.duk_put_prop_string(-2, "colorUiDark")
  pushColor(colorHit)
  discard ctx.duk_put_prop_string(-2, "colorHit")
  pushColor(colorHeal)
  discard ctx.duk_put_prop_string(-2, "colorHeal")
  pushColor(colorClear)
  discard ctx.duk_put_prop_string(-2, "colorClear")
  pushColor(colorWhite)
  discard ctx.duk_put_prop_string(-2, "colorWhite")
  pushColor(colorBlack)
  discard ctx.duk_put_prop_string(-2, "colorBlack")
  pushColor(colorGray)
  discard ctx.duk_put_prop_string(-2, "colorGray")
  pushColor(colorRoyal)
  discard ctx.duk_put_prop_string(-2, "colorRoyal")
  pushColor(colorCoral)
  discard ctx.duk_put_prop_string(-2, "colorCoral")
  pushColor(colorOrange)
  discard ctx.duk_put_prop_string(-2, "colorOrange")
  pushColor(colorRed)
  discard ctx.duk_put_prop_string(-2, "colorRed")
  pushColor(colorMagenta)
  discard ctx.duk_put_prop_string(-2, "colorMagenta")
  pushColor(colorPurple)
  discard ctx.duk_put_prop_string(-2, "colorPurple")
  pushColor(colorGreen)
  discard ctx.duk_put_prop_string(-2, "colorGreen")
  pushColor(colorBlue)
  discard ctx.duk_put_prop_string(-2, "colorBlue")
  pushColor(colorPink)
  discard ctx.duk_put_prop_string(-2, "colorPink")
  pushColor(colorYellow)
  discard ctx.duk_put_prop_string(-2, "colorYellow")

  discard ctx.duk_put_global_string("Color")

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

  #region Value functions

  # px(x: float): int
  setGlobalFunc("px", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_push_number(ctx.duk_require_number(0).float32.px.cdouble) # return argv[0].px
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

  # hoverOffset(scl: float, offset: float = 0): Vec2
  setGlobalFunc("hoverOffset", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      scl = ctx.duk_require_number(0).float
      offset = ctx.duk_get_number_default(1, 0).float
      res = vec2(0f, (fau.time + offset).sin(scl, 0.14f) - 0.14f)
    pushVec2(res)
    return 1
  ))

  # rad(x: float): float
  setGlobalFunc("rad", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_push_number(ctx.duk_require_number(0).float32.rad.cdouble) # return argv[0].rad
    return 1
  ))

  #endregion

  #region Pattern functions
  #endregion

proc addNamespace*(name: string) =
  discard ctx.duk_push_object()
  discard ctx.duk_put_global_string(name)

proc getScriptJs*(namespace, name: string): (proc()) =
  capture name:
    return (proc() =
      discard ctx.duk_get_global_string(namespace)  # get namespace
      discard ctx.duk_get_prop_string(-1, name)     # get function
      ctx.duk_require_function(-1)                  # verify that it is a function
      ctx.duk_dup(-2)                               # duplicate namespace as this

      let err = ctx.duk_pcall_method(0)             # call function
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
      currentUnit = unit

      # Get function
      discard ctx.duk_get_global_string(namespace)
      discard ctx.duk_get_global_string(name)
      ctx.duk_require_function(-1)
      ctx.duk_dup(-2)

      # Push arguments
      pushVec2(basePos)

      # Call function
      let err = ctx.duk_pcall_method(1)
      if err != 0:
        echo "Error in script ", namespace, ".", name, ":"
        echo ctx.duk_safe_to_string(-1)

      ctx.duk_pop_2()
    )

proc getUnitAbilityJs*(namespace, name: string): (proc(entity: EntityRef, moves: int)) =
  capture name:
    return (proc(entity: EntityRef, moves: int) =
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

      ctx.duk_pop_2()
    )
