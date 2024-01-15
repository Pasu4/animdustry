import core, vars, std/json, std/tables, std/math, os, mathexpr, types, patterns, fau/g2/bloom

var
  evalsInitialized = false
  drawEval_x = newEvaluator()               # General draw evaluator, holds x component of vectors
  drawEval_y = newEvaluator()               # Holds y component of vectors
  colorTable = initTable[string, Color]()   # Holds color variables
  drawBloomA, drawBloomB: proc()            # Draws bloom (it's unfortunate but what can you do)

# Avoid circular dependency
proc getTexture(unit: Unit, name: string = ""): Texture =
  ## Loads a unit texture from the textures/ folder. Result is cached. Crashes if the texture isn't found!
  if not unit.textures.hasKey(name):
    let tex =
      if not unit.isModded:
        echo "Loading asset ", "textures/" & unit.name & name & ".png"
        loadTextureAsset("textures/" & unit.name & name & ".png")
      else:
        echo "Loading file ", unit.modPath / "unitPortraits" / unit.name & name & ".png"
        loadTextureFile(unit.modPath / "unitPortraits" / unit.name & name & ".png")
    tex.filter = tfLinear
    unit.textures[name] = tex
    return tex
  return unit.textures[name]

template drawBloom(body: untyped) =
  drawBloomA()
  body
  drawBloomB()

#region Functions callable from formulas

# getScl(base = 0.175f)
proc apiGetScl(args: seq[float]): float =
  return (args[0] + 0.12f * (1f - splashTime).pow(10f)) * fau.cam.size.y / 17f

template apiGetScl_0: float = (0.175 + 0.12f * (1f - splashTime).pow(10f)) * fau.cam.size.y / 17f

# hoverOffset(scl = 0.65f, offset = 0f)
proc apiHoverOffset_x(args: seq[float]): float =
  return 0f
template apiHoverOffset_x_0: float = 0f

proc apiHoverOffset_y(args: seq[float]): float =
  var vArgs = args
  if vArgs.len < 2: vArgs.add(0f)
  return (fau.time + vArgs[1]).sin(vArgs[0], 0.14f) - 0.14f
template apiHoverOffset_y_0: float = (fau.time + 0f).sin(0.65f, 0.14f) - 0.14f

# vec2(x, y: float)
proc apiVec2_x(args: seq[float]): float =
  return args[0]

proc apiVec2_y(args: seq[float]): float =
  return args[1]

# px(val: float)
proc apiPx(args: seq[float]): float =
  return args[0].px

#endregion

# Parses a color from a string
proc getColor(str: string): Color =
  if str in colorTable:
    return colorTable[str]
  else:
    return parseColor(str) # fau color

# Add functions and constants that can be used in formulas.
# Must be called before any other function in the API
proc initJsonApi*(bloomA, bloomB: proc()) =
  # Set bloom procs
  # For whatever reason, sysDraw only exists within main
  drawBloomA = bloomA
  drawBloomB = bloomB

  # Init evals
  for eval in [drawEval_x, drawEval_y]:
    # Functions
    # eval.addFunc("getScl", apiGetScl, 1)
    # eval.addFunc("hoverOffset", apiHoverOffset)
    eval.addFunc("px", apiPx, 1)
    # Constants
    eval.addVar("shadowOffset", 0.3f)

  # Vector functions
  drawEval_x.addFunc("getScl", apiGetScl, 1)
  drawEval_y.addFunc("getScl", apiGetScl, 1)
  drawEval_x.addFunc("hoverOffset", apiHoverOffset_x, -1)
  drawEval_y.addFunc("hoverOffset", apiHoverOffset_y, -1)
  drawEval_x.addFunc("vec2", apiVec2_x, 2)
  drawEval_y.addFunc("vec2", apiVec2_y, 2)
  
  # Colors
  colorTable["shadowColor"]   = rgba(0f, 0f, 0f, 0.4f)

  colorTable["colorAccent"]   = colorAccent
  colorTable["colorUi"]       = colorUi
  colorTable["colorUiDark"]   = colorUiDark
  colorTable["colorHit"]      = colorHit
  colorTable["colorHeal"]     = colorHeal

  colorTable["colorClear"]    = colorClear
  colorTable["colorWhite"]    = colorWhite
  colorTable["colorBlack"]    = colorBlack
  colorTable["colorGray"]     = colorGray
  colorTable["colorRoyal"]    = colorRoyal
  colorTable["colorCoral"]    = colorCoral
  colorTable["colorOrange"]   = colorOrange
  colorTable["colorRed"]      = colorRed
  colorTable["colorMagenta"]  = colorMagenta
  colorTable["colorPurple"]   = colorPurple
  colorTable["colorGreen"]    = colorGreen
  colorTable["colorBlue"]     = colorBlue
  colorTable["colorPink"]     = colorPink
  colorTable["colorYellow"]   = colorYellow

# Update variables that can be used in formulas
proc updateDrawEvals(unit: Unit, basePos: Vec2) =
  # if not evalsInitialized:
  #   evalsInitialized = true
  #   initEvals()
  
  for eval in [drawEval_x, drawEval_y]:
    eval.addVar("state_secs", state.secs)
    eval.addVar("state_lastSecs", state.lastSecs)
    eval.addVar("state_time", state.time)
    eval.addVar("state_rawBeat", state.rawBeat)
    eval.addVar("state_moveBeat", state.moveBeat)
    eval.addVar("state_hitTime", state.hitTime)
    eval.addVar("state_healTime", state.healTime)
    eval.addVar("state_points", state.points.float)
    eval.addVar("state_turn", state.turn.float)
    eval.addVar("state_copperReceived", state.copperReceived.float)
    eval.addVar("state_hits", state.hits.float)
    eval.addVar("state_totalHits", state.totalHits.float)
    eval.addVar("state_misses", state.misses.float)

  # Vector
  drawEval_x.addVar("basePos", basePos.x)
  drawEval_y.addVar("basePos", basePos.y)
  drawEval_x.addVar("_getScl", apigetScl_0())
  drawEval_y.addVar("_getScl", apiGetScl_0())
  drawEval_x.addVar("_hoverOffset", apiHoverOffset_x_0())
  drawEval_y.addVar("_hoverOffset", apiHoverOffset_y_0())
  drawEval_x.addVar("playerPos", state.playerPos.x.float)
  drawEval_y.addVar("playerPos", state.playerPos.y.float)

# Parses a draw stack into a sequence of procs
proc parseDrawStack(drawStack: JsonNode): seq[proc(unit: Unit, basePos: Vec2)] =
  var procs = newSeq[proc(unit: Unit, basePos: Vec2)]()
  for elem in drawStack.getElems():
    echo elem["type"].getStr()
    case elem["type"].getStr()
    # Setters
    of "SetFloat", "SetVec2":
      let
        name = elem["name"].getStr()
        value = elem["value"].getStr()
      procs.add(proc(u: Unit, v: Vec2) =
        drawEval_x.addVar(name, drawEval_x.eval(value))
        drawEval_y.addVar(name, drawEval_y.eval(value)))

    of "SetColor":
      let
        name = elem["name"].getStr()
        value = elem["value"].getStr()
      procs.add(proc(u: Unit, v: Vec2) = colorTable[name] = getColor(value))

    # Patterns
    of "DrawStripes":
      let
        col1 = elem{"col1"}.getStr($colorPink)
        col2 = elem{"col2"}.getStr($colorPink.mix(colorWhite, 0.2f))
        angle = elem{"angle"}.getStr($elem{"angle"}.getFloat(135f.rad))
      procs.add(proc(u: Unit, v: Vec2) = patStripes(getColor(col1), getColor(col2), drawEval_x.eval(angle)))
      
    of "DrawVertGradient":
      let
        col1 = elem{"col1"}.getStr($colorClear)
        col2 = elem{"col2"}.getStr($colorClear)
      procs.add(proc(u: Unit, v: Vec2) = patVertGradient(getColor(col1), getColor(col2)))
    
    of "DrawLines":
      let
        col = elem{"col"}.getStr($colorWhite)
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(30))
        angle = elem{"angle"}.getStr($elem{"angle"}.getFloat(45f.rad))
      procs.add(proc(u: Unit, v: Vec2) = patLines(
        getColor(col),
        drawEval_x.eval(seed).int,
        drawEval_x.eval(amount).int,
        drawEval_x.eval(angle)))
    
    of "DrawSquares":
      let
        col = elem{"col"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
        seed = elem{"angle"}.getStr($elem{"angle"}.getInt(2))
      procs.add(proc(u: Unit, v: Vec2) = patSquares(
        getColor(col),
        drawEval_x.eval(time),
        drawEval_x.eval(amount).int,
        drawEval_x.eval(seed).int))

    # Draw
    of "DrawFillPoly":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      procs.add(proc(u: Unit, v: Vec2) = fillPoly(
        vec2(drawEval_x.eval(pos), drawEval_y.eval(pos)),
        drawEval_x.eval(sides).int,
        drawEval_x.eval(radius),
        drawEval_x.eval(rotation),
        getColor(color),
        drawEval_x.eval(z)))
    
    of "DrawPoly":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      procs.add(proc(u: Unit, v: Vec2) = poly(
        vec2(drawEval_x.eval(pos), drawEval_y.eval(pos)),
        drawEval_x.eval(sides).int,
        drawEval_x.eval(radius),
        drawEval_x.eval(rotation),
        drawEval_x.eval(stroke),
        getColor(color),
        drawEval_x.eval(z)))
    
    of "DrawUnit":
      let
        pos = elem["pos"].getStr()
        scl = elem{"scl"}.getStr($elem{"scl"}.getFloat(1f))
        color = elem{"color"}.getStr($colorWhite)
        part = elem{"part"}.getStr("")
      echo color, " -> ", getColor(color)
      procs.add(proc(u: Unit, v: Vec2) =
        # echo "drawing: ", vec2(drawEval_x.eval(pos), drawEval_y.eval(pos)), ", ", vec2(drawEval_x.eval(scl), drawEval_y.eval(scl)), ", ", getColor(color), ", ", color
        u.getTexture(part).draw(
          vec2(drawEval_x.eval(pos), drawEval_y.eval(pos)),
          scl = vec2(drawEval_x.eval(scl), drawEval_y.eval(scl)),
          color = getColor(color)))
    
    # Bloom
    of "DrawBloom": # contains a body, so recurse
      let body = parseDrawStack(elem["body"])
      procs.add(proc(u: Unit, v: Vec2) = # copied from main
        drawBloom:
          for p in body:
            p(u, v)
      )
    
    else:
      echo "!! Critical error !!"
  return procs

# Returns a proc for drawing a unit portrait
proc getUnitDraw*(drawStack: JsonNode): (proc(unit: Unit, basePos: Vec2)) =
  var procs = parseDrawStack(drawStack);
  # procs.add(proc(u: Unit, v: Vec2) = echo "test")
  return (proc(u: Unit, v: Vec2) =
    updateDrawEvals(u, v)
    for p in procs:
      p(u, v)
  )
  
