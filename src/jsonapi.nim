import core, vars, std/json, std/tables, std/math, os, mathexpr, types, patterns, sugar

var
  drawEval_x = newEvaluator()               # General draw evaluator, holds x component of vectors
  drawEval_y = newEvaluator()               # Holds y component of vectors
  colorTable = initTable[string, Color]()   # Holds color variables
  drawBloomA, drawBloomB: proc()            # Draws bloom (it's unfortunate but what can you do)
  currentUnit: Unit                         # The current unit

#region Procs copied to avoid circular dependency
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

proc musicTime(): float = state.secs

#endregion

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
proc updateEvals() =
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
    eval.addVar("state_hits", state.hits.float)
    eval.addVar("state_totalHits", state.totalHits.float)
    eval.addVar("state_misses", state.misses.float)

    eval.addVar("fau_time", fau.time)

  # Vector
  drawEval_x.addVar("_getScl", apigetScl_0())
  drawEval_y.addVar("_getScl", apiGetScl_0())
  drawEval_x.addVar("_hoverOffset", apiHoverOffset_x_0())
  drawEval_y.addVar("_hoverOffset", apiHoverOffset_y_0())
  drawEval_x.addVar("playerPos", state.playerPos.x.float)
  drawEval_y.addVar("playerPos", state.playerPos.y.float)

# Parses a draw stack into a sequence of procs
proc parseDrawStack(drawStack: JsonNode): seq[proc()] =
  # Shortcuts
  template evalVec2(str: string): Vec2 = vec2(drawEval_x.eval(str), drawEval_y.eval(str))
  template eval(str: string): float = drawEval_x.eval(str)
  
  var procs = newSeq[proc()]()
  for elem in drawStack.getElems():
    echo elem["type"].getStr()
    case elem["type"].getStr()
    # Setters
    of "SetFloat", "SetVec2":
      let
        name = elem["name"].getStr()
        value = elem["value"].getStr()
      capture name, value: # This has to be done so the strings can be captured
        procs.add(proc() =
          drawEval_x.addVar(name, drawEval_x.eval(value))
          drawEval_y.addVar(name, drawEval_y.eval(value)))

    of "SetColor":
      let
        name = elem["name"].getStr()
        value = elem["value"].getStr()
      capture name, value:
        procs.add(proc() = colorTable[name] = getColor(value))

    # Patterns
    of "DrawFft":
      let
        pos = elem["pos"].getStr()
        radius = elem{"radius"}.getStr($elem{"radius"}.getFloat(90f.px))
        length = elem{"length"}.getStr($elem{"length"}.getFloat(8f))
        color = elem{"color"}.getStr($colorWhite)
      capture pos, radius, length, color:
        procs.add(proc() = patFft(evalVec2(pos), eval(radius), eval(length), getColor(color)))
    
    of "DrawTiles":
      procs.add(proc() = patTiles())
    
    of "DrawTilesFft":
      procs.add(proc() = patTilesFft())
    
    of "DrawTilesSquare":
      let
        col1 = elem{"col1"}.getStr($colorWhite)
        col2 = elem{"col2"}.getStr($colorBlue)
      capture col1, col2:
        procs.add(proc() = patTilesSquare(getColor(col1), getColor(col2)))
    
    of "DrawBackground":
      let col = elem["col"].getStr()
      capture col:
        procs.add(proc() = patBackground(getColor(col)))
    
    of "DrawStripes":
      let
        col1 = elem{"col1"}.getStr($colorPink)
        col2 = elem{"col2"}.getStr($colorPink.mix(colorWhite, 0.2f))
        angle = elem{"angle"}.getStr($elem{"angle"}.getFloat(135f.rad))
      capture col1, col2, angle:
        procs.add(proc() = patStripes(getColor(col1), getColor(col2), eval(angle)))

    of "DrawBeatSquare":
      let col = elem{"col"}.getStr($colorPink.mix(colorWhite, 0.7f))
      capture col:
        procs.add(proc() = patBeatSquare(getColor(col)))
    
    of "DrawBeatAlt":
      let col = elem["col"].getStr()
      capture col:
        procs.add(proc() = patBeatAlt(getColor(col)))

    of "DrawTriSquare":
      let
        pos = elem["pos"].getStr()
        col = elem["col"].getStr()
        len = elem{"len"}.getStr($elem{"len"}.getFloat(4f))
        rad = elem{"rad"}.getStr($elem{"rad"}.getFloat(2f))
        offset = elem{"offset"}.getStr($elem{"offset"}.getFloat(45f.rad))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(4))
        sides = elem{"sides"}.getStr($elem{"sides"}.getInt(3))
        shapeOffset = elem{"shapeOffset"}.getStr($elem{"shapeOffset"}.getFloat(0f.rad))
      capture pos, col, len, rad, offset, amount, sides, shapeOffset:
        procs.add(proc() = patTriSquare(evalVec2(pos), getColor(col), eval(len), eval(rad), eval(offset), eval(amount).int, eval(sides).int, eval(shapeOffset)))

    of "DrawSpin":
      let
        col1 = elem["col1"].getStr()
        col2 = elem["col2"].getStr()
        blades = elem{"blades"}.getStr($elem{"blades"}.getInt(10))
      capture col1, col2, blades:
        procs.add(proc() = patSpin(getColor(col1), getColor(col2), eval(blades).int))
      
    of "DrawSpinGradient":
      let
        pos = elem["pos"].getStr()
        col1 = elem["col1"].getStr()
        col2 = elem["col2"].getStr()
        len = elem{"len"}.getStr($elem{"len"}.getFloat(5f))
        blades = elem{"blades"}.getStr($elem{"blades"}.getInt(10))
        spacing = elem{"spacing"}.getStr($elem{"spacing"}.getInt(2))
      capture pos, col1, col2, len, blades, spacing:
        procs.add(proc() = patSpinGradient(evalVec2(pos), getColor(col1), getColor(col2), eval(len), eval(blades).int, eval(spacing).int))
    
    of "DrawSpinShape":
      let
        col1 = elem["col1"].getStr()
        col2 = elem{"col2"}.getStr($col1)
        sides = elem{"sides"}.getStr($elem{"sides"}.getInt(4))
        rad = elem{"rad"}.getStr($elem{"rad"}.getFloat(3f))
        turnSpeed = elem{"turnSpeed"}.getStr($elem{"turnSpeed"}.getFloat(19f.rad))
        rads = elem{"rads"}.getStr($elem{"rads"}.getInt(6))
        radsides = elem{"radsides"}.getStr($elem{"radsides"}.getInt(4))
        radOff = elem{"radOff"}.getStr($elem{"radOff"}.getFloat(7f))
        radrad = elem{"radrad"}.getStr($elem{"radrad"}.getFloat(1.3f))
        radrotscl = elem{"radrotscl"}.getStr($elem{"radrotscl"}.getFloat(0.25f))
      capture col1, col2, sides, rad, turnSpeed, rads, radsides, radOff, radrad, radrotscl:
        procs.add(proc() = patSpinShape(getColor(col1), getColor(col2), eval(sides).int, eval(rad), eval(turnSpeed), eval(rads).int, eval(radsides).int, eval(radOff), eval(radrad), eval(radrotscl)))
    
    of "DrawShapeBack":
      let
        col1 = elem["col1"].getStr()
        col2 = elem["col2"].getStr()
        sides = elem{"sides"}.getStr($elem{"sides"}.getInt(4))
        spacing = elem{"spacing"}.getStr($elem{"spacing"}.getFloat(2.5f))
        angle = elem{"angle"}.getStr($elem{"angle"}.getFloat(90f.rad))
      capture col1, col2, sides, spacing, angle:
        procs.add(proc() = patShapeBack(getColor(col1), getColor(col2), eval(sides).int, eval(spacing), eval(angle)))
    
    of "DrawFadeShapes":
      let col = elem["col"].getStr()
      capture col:
        procs.add(proc() = patFadeShapes(getColor(col)))
    
    of "DrawRain":
      let amount = elem{"amount"}.getStr($elem{"amount"}.getInt(80))
      capture amount:
        procs.add(proc() = patRain(eval(amount).int))

    of "DrawPetals":
      procs.add(proc() = patPetals())
    
    of "DrawSkats":
      procs.add(proc() = patSkats())

    of "DrawClouds":
      let col = elem{"col"}.getStr($colorWhite)
      capture col:
        procs.add(proc() = patClouds(getColor(col)))
    
    of "DrawLongClouds":
      let col = elem{"col"}.getStr($colorWhite)
      capture col:
        procs.add(proc() = patLongClouds(getColor(col)))

    of "DrawStars":
      let
        col = elem{"col"}.getStr($colorWhite)
        flash = elem{"flash"}.getStr($colorWhite)
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(40))
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
      capture col, flash, amount, seed:
        procs.add(proc() = patStars(getColor(col), getColor(flash), eval(amount).int, eval(seed).int))

    of "DrawTris":
      let
        col1 = elem{"col1"}.getStr($colorWhite)
        col2 = elem{"col2"}.getStr($colorWhite)
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
      capture col1, col2, amount, seed:
        procs.add(proc() = patTris(getColor(col1), getColor(col2), eval(amount).int, eval(seed).int))

    of "DrawBounceSquares":
      let col = elem{"col"}.getStr($colorWhite)
      capture col:
        procs.add(proc() = patBounceSquares(getColor(col)))

    of "DrawCircles":
      let
        col = elem{"col"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
        minSize = elem{"minSize"}.getStr($elem{"minSize"}.getFloat(2f))
        maxSize = elem{"maxSize"}.getStr($elem{"maxSize"}.getFloat(7f))
        moveSpeed = elem{"moveSpeed"}.getStr($elem{"moveSpeed"}.getFloat(0.2f))
      capture col, time, amount, seed, minSize, maxSize, moveSpeed:
        procs.add(proc() = patCircles(getColor(col), eval(time), eval(amount).int, eval(seed).int, eval(minSize).float32..eval(maxSize).float32, eval(moveSpeed)))

    of "DrawRadTris":
      let
        col = elem{"col"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
      capture col, time, amount, seed:
        procs.add(proc() = patRadTris(getColor(col), eval(time), eval(amount).int, eval(seed).int))
    
    of "DrawMissiles":
      let
        col = elem{"col"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
      capture col, time, amount, seed:
        procs.add(proc() = patMissiles(getColor(col), eval(time), eval(amount).int, eval(seed).int))

    of "DrawFallSquares":
      let
        col1 = elem{"col1"}.getStr($colorWhite)
        col2 = elem{"col2"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
      capture col1, col2, time, amount:
        procs.add(proc() = patFallSquares(getColor(col1), getColor(col2), eval(time), eval(amount).int))

    of "DrawFlame":
      let
        col1 = elem{"col1"}.getStr($colorWhite)
        col2 = elem{"col2"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(80))
      capture col1, col2, time, amount:
        procs.add(proc() = patFlame(getColor(col1), getColor(col2), eval(time), eval(amount).int))
    
    of "DrawSquares":
      let
        col = elem{"col"}.getStr($colorWhite)
        time = (if elem{"time"}.isNil: "state_time" else: elem{"time"}.getStr($elem{"time"}.getFloat()))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(50))
        seed = elem{"angle"}.getStr($elem{"angle"}.getInt(2))
      capture col, time, amount, seed:
        procs.add(proc() = patSquares(getColor(col), eval(time), eval(amount).int, eval(seed).int))

    of "DrawRoundLine":
      let
        pos = elem["pos"].getStr()
        angle = elem["angle"].getStr($elem["angle"].getFloat())
        len = elem["len"].getStr($elem["len"].getFloat())
        color = elem{"color"}.getStr($colorWhite)
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f))
      capture pos, angle, len, color, stroke:
        procs.add(proc() = roundLine(evalVec2(pos), eval(angle), eval(len), getColor(color), eval(stroke)))

    of "DrawLines":
      let
        col = elem{"col"}.getStr($colorWhite)
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(1))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(30))
        angle = elem{"angle"}.getStr($elem{"angle"}.getFloat(45f.rad))
      capture col, seed, amount, angle:
        procs.add(proc() = patLines(getColor(col), eval(seed).int, eval(amount).int, eval(angle)))

    of "DrawRadLines":
      let
        col = elem{"col"}.getStr($colorWhite)
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(6))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(40))
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(0.25f))
        posScl = elem{"posScl"}.getStr($elem{"posScl"}.getFloat(1f))
        lenScl = elem{"lenScl"}.getStr($elem{"lenScl"}.getFloat(1f))
      capture col, seed, amount, stroke, posScl, lenScl:
        procs.add(proc() = patRadLines(getColor(col), eval(seed).int, eval(amount).int, eval(stroke), eval(posScl), eval(lenScl)))

    of "DrawRadCircles":
      let
        col = elem{"col"}.getStr($colorWhite)
        seed = elem{"seed"}.getStr($elem{"seed"}.getInt(7))
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(40))
        fin = elem{"fin"}.getStr($elem{"fin"}.getFloat(0.5f))
      capture col, seed, amount, fin:
        procs.add(proc() = patRadCircles(getColor(col), eval(seed).int, eval(amount).int, eval(fin)))
      
    of "DrawSpikes":
      let
        pos = elem["pos"].getStr()
        col = elem{"col"}.getStr($colorWhite)
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(10))
        offset = elem{"offset"}.getStr($elem{"offset"}.getFloat(8f))
        len = elem{"len"}.getStr($elem{"len"}.getFloat(3f))
        angleOffset = elem{"angleOffset"}.getStr($elem{"angleOffset"}.getFloat(0f))
      capture pos, col, amount, offset, len, angleOffset:
        procs.add(proc() = patSpikes(evalVec2(pos), getColor(col), eval(amount).int, eval(offset), eval(len), eval(angleOffset)))

    of "DrawGradient":
      let
        col1 = elem{"col1"}.getStr($colorClear)
        col2 = elem{"col2"}.getStr($colorClear)
        col3 = elem{"col3"}.getStr($colorClear)
        col4 = elem{"col4"}.getStr($colorClear)
      capture col1, col2, col3, col4:
        procs.add(proc() = patGradient(getColor(col1), getColor(col2), getColor(col3), getColor(col4)))

    of "DrawVertGradient":
      let
        col1 = elem{"col1"}.getStr($colorClear)
        col2 = elem{"col2"}.getStr($colorClear)
      capture col1, col2:
        procs.add(proc() = patVertGradient(getColor(col1), getColor(col2)))

    of "DrawZoom":
      let
        col = elem{"col"}.getStr($colorWhite)
        offset = elem{"offset"}.getStr($elem{"offset"}.getFloat(0f))        
        amount = elem{"amount"}.getStr($elem{"amount"}.getInt(10))
        sides = elem{"sides"}.getStr($elem{"sides"}.getInt(4))
      capture col, offset, amount, sides:
        procs.add(proc() = patZoom(getColor(col), eval(offset), eval(amount).int, eval(sides).int))

    of "DrawFadeOut":
      let time = elem["time"].getStr($elem["time"].getFloat())
      capture time:
        procs.add(proc() = patFadeOut(eval(time)))
    
    of "DrawFadeIn":
      let time = elem["time"].getStr($elem["time"].getFloat())
      capture time:
        procs.add(proc() = patFadeIn(eval(time)))

    of "DrawSpace":
      let col = elem["col"].getStr()
      capture col:
        procs.add(proc() = patSpace(getColor(col)))

    # Draw
    of "DrawFillPoly":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, sides, radius, rotation, color, z:
        procs.add(proc() = fillPoly(evalVec2(pos), eval(sides).int, eval(radius), eval(rotation), getColor(color), eval(z)))
    
    of "DrawPoly":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, sides, radius, rotation, stroke, color, z:
        procs.add(proc() = poly(evalVec2(pos), eval(sides).int, eval(radius), eval(rotation), eval(stroke), getColor(color), eval(z)))
    
    of "DrawUnit":
      let
        pos = elem["pos"].getStr()
        scl = elem{"scl"}.getStr("1") # Same as "vec2(1, 1)" in this case
        color = elem{"color"}.getStr($colorWhite)
        part = elem{"part"}.getStr("")
      capture pos, scl, color, part:
        procs.add(proc() = currentUnit.getTexture(part).draw(evalVec2(pos), scl = evalVec2(scl), color = getColor(color)))
    
    # Bloom
    of "DrawBloom": # contains a body, so recurse
      let body = parseDrawStack(elem["body"])
      capture body:
        procs.add(proc() = # copied from main
          drawBloom:
            for p in body:
              p()
        )
    
    else:
      echo "!! Critical error !!"
  return procs

# Returns a proc for drawing a unit portrait
proc getUnitDraw*(drawStack: JsonNode): (proc(unit: Unit, basePos: Vec2)) =

  # Parse
  var procs = parseDrawStack(drawStack);
  
  capture procs:
    return (proc(unit: Unit, basePos: Vec2) =
      updateEvals()
      # Additional updates to eval
      currentUnit = unit
      drawEval_x.addVar("basePos", basePos.x)
      drawEval_y.addVar("basePos", basePos.y)

      # execute
      for p in procs:
        p()
    )
  
