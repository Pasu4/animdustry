import system, math, sugar, sequtils
import core, vars, fau/[fmath, color], pkg/polymorph
import duktape/js
import types, apivars, dukconst, patterns

type JavaScriptError* = object of CatchableError

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

proc getColorDefault(idx: cint, default: Color): Color =
  let invalid = (ctx.duk_get_top() <= idx) or
    (ctx.duk_check_type(idx, DUK_TYPE_OBJECT) != 1) or
    (ctx.duk_get_prop_string(idx, "r") == 0) or
    (ctx.duk_get_prop_string(idx, "g") == 0) or
    (ctx.duk_get_prop_string(idx, "b") == 0) or
    (ctx.duk_get_prop_string(idx, "a") == 0)
  # ctx.duk_pop_n(4)

  if invalid:
    return default
  
  let r = ctx.duk_get_number(-4).float
  let g = ctx.duk_get_number(-3).float
  let b = ctx.duk_get_number(-2).float
  let a = ctx.duk_get_number(-1).float
  return rgba(r, g, b, a)

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

  # hoverOffset(scl: float = 0.65, offset: float = 0): Vec2
  setGlobalFunc("hoverOffset", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      scl = ctx.duk_get_number_default(0, 0.65).float
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

  # beatSpacing(): float
  setGlobalFunc("beatSpacing", 0, (proc(ctx: DTContext): cint{.stdcall.} =
    ctx.duk_push_number(1.0 / (state.currentBpm / 60.0))
    return 1
  ))

  #endregion

  #region Pattern functions

  # drawStripes(col1: Color = colorPink, col2: Color = Color.mix(colorPink, colorWhite, 0.2), angle: float = rad(135))
  setGlobalFunc("drawStripes", 3, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorPink)
      col2 = getColorDefault(1, apiMixColor(colorPink, colorWhite, 0.2))
      angle = ctx.duk_get_number_default(2, rad(135)).float
    patStripes(col1, col2, angle)
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

  # drawVertGradient(col1: Color = colorClear, col2: Color = colorClear)
  setGlobalFunc("drawVertGradient", 2, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      col1 = getColorDefault(0, colorClear)
      col2 = getColorDefault(1, colorClear)
    patVertGradient(col1, col2)
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

  #region Effects

  # effectExplode(pos: Vec2)
  setGlobalFunc("effectExplode", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
    apiEffectExplode(pos)
    return 0
  ))

  #endregion

  #region Abilities

  # damageBlocks(pos: Vec2)
  setGlobalFunc("damageBlocks", 1, (proc(ctx: DTContext): cint{.stdcall.} =
    let
      pos = getVec2(0)
    apiDamageBlocks(vec2i(pos.x.int, pos.y.int))
    return 0
  ))

  #endregion

  #region Other functions

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
