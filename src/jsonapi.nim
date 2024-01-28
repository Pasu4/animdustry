import core, vars, os, mathexpr, types, patterns, sugar, pkg/polymorph, fau/fmath
import std/[json, tables, math, strutils, sequtils], system

type Procedure* = ref object
  script*: proc()                                 # The script of the procedure
  defaultValues*: Table[string, string]           # The default values of parameters
  # defaultFloats*: Table[string, string]          # The default values of float parameters
  # defaultColors*: Table[string, string]          # The default values of color parameters

let
  formations = {
    "d4": d4.toSeq(),
    "d4mid": d4mid.toSeq(),
    "d4edge": d4edge.toSeq(),
    "d8": d8.toSeq(),
    "d8mid": d8mid.toSeq()
  }.toTable

var
  eval_x = newEvaluator()                       # General draw evaluator, holds x component of vectors
  eval_y = newEvaluator()                       # Holds y component of vectors
  colorTable = initTable[string, Color]()       # Holds color variables
  drawBloomA, drawBloomB: proc()                # Draws bloom (it's unfortunate but what can you do)
  currentUnit: Unit                             # The current unit
  currentEntityRef: EntityRef                   # The current EntityRef (for abilityProc)
  isBreaking = false                            # Flow control: break
  isReturning = false                           # Flow control: return
  currentNamespace*: string                     # Current namespace for resolving procedures
  procedures* = initTable[string, Procedure]()  # Holds user-defined procedures
  
  # Procs from main
  # I unfortunately see no better way to do this.
  fetchGridPosition*: (proc(entity: EntityRef): Vec2i)
  fetchLastMove*: (proc(entity: EntityRef): Vec2i)

  apiMakeDelay*: proc(delay: int, callback: proc())
  apiMakeBullet*: proc(pos: Vec2i, dir: Vec2i, tex = "bullet")
  apiMakeTimedBullet*: proc(pos: Vec2i, dir: Vec2i, tex = "bullet", life = 3)
  apiMakeConveyor*: proc(pos: Vec2i, dir: Vec2i, length = 2, tex = "conveyor", gen = 0)
  apiMakeLaserSegment*: proc(pos: Vec2i, dir: Vec2i)
  apiMakeRouter*: proc(pos: Vec2i, length = 2, life = 2, diag = false, sprite = "router", alldir = false)
  apiMakeSorter*: proc(pos: Vec2i, mdir: Vec2i, moveSpace = 2, spawnSpace = 2, length = 1)
  apiMakeTurret*: proc(pos: Vec2i, face: Vec2i, reload = 4, life = 8, tex = "duo")
  apiMakeArc*: proc(pos: Vec2i, dir: Vec2i, tex = "arc", bounces = 1, life = 3)
  apiMakeWall*: proc(pos: Vec2i, sprite = "wall", life = 10, health = 3)

  apiMakeDelayBullet*: proc(pos, dir: Vec2i, tex = "")
  apiMakeDelayBulletWarn*: proc(pos, dir: Vec2i, tex = "")
  apiMakeBulletCircle*: proc(pos: Vec2i, tex = "")
  apiMakeLaser*: proc(pos, dir: Vec2i)

  apiAddPoints*: proc(amount = 1)
  apiDamageBlocks*: proc(target: Vec2i)

  #apiEffectExplode*: proc(pos: Vec2, rotation = 0.0'f32, color = colorWhite, life = 0.4'f32, size = 0.0'f32, parent = NO_ENTITY_REF)
  apiEffectExplode*: proc(pos: Vec2)
  apiEffectExplodeHeal*: proc(pos: Vec2)
  # apiEffectLaserShoot*: proc()
  apiEffectWarn*: proc(pos: Vec2, life: float32)
  apiEffectWarnBullet*: proc(pos: Vec2, life: float32, rotation: float32 = 0.0)
  apiEffectStrikeWave*: proc(pos: Vec2, life: float32, rotation: float32 = 0.0)

# Export main's procs to the API
template exportProcs* =
  # Fetch
  jsonapi.fetchGridPosition = proc(entity: EntityRef): Vec2i = entity.fetch(GridPos).vec
  jsonapi.fetchLastMove = proc(entity: EntityRef): Vec2i = entity.fetch(Input).lastMove

  # Makers
  jsonapi.apiMakeDelay        = makeDelay
  jsonapi.apiMakeBullet       = makeBullet
  jsonapi.apiMakeTimedBullet  = makeTimedBullet
  jsonapi.apiMakeConveyor     = makeConveyor
  jsonapi.apiMakeLaserSegment = makeLaser
  jsonapi.apiMakeRouter       = makeRouter
  jsonapi.apiMakeSorter       = makeSorter
  jsonapi.apiMakeTurret       = makeTurret
  jsonapi.apiMakeArc          = makeArc
  jsonapi.apiMakeWall         = makeWall

  jsonapi.apiMakeDelayBullet      = proc(pos, dir: Vec2i, tex = "") = delayBullet(pos, dir, tex)
  jsonapi.apiMakeDelayBulletWarn  = proc(pos, dir: Vec2i, tex = "") = delayBulletWarn(pos, dir, tex)
  jsonapi.apiMakeBulletCircle     = proc(pos: Vec2i,      tex = "") = bulletCircle(pos, tex)
  jsonapi.apiMakeLaser            = proc(pos, dir: Vec2i)           = laser(pos, dir)

  # Other
  jsonapi.apiAddPoints = addPoints
  jsonapi.apiDamageBlocks = damageBlocks

  # Effects (evil post-compile-time signature apparently)
  jsonapi.apiEffectExplode = proc(pos: Vec2) = effectExplode(pos)
  jsonapi.apiEffectExplodeHeal = proc(pos: Vec2) = effectExplodeHeal(pos)
  jsonapi.apiEffectWarn = proc(pos: Vec2, life: float32) = effectWarn(pos, life = life)
  jsonapi.apiEffectWarnBullet = proc(pos: Vec2, life: float32, rotation: float32) = effectWarnBullet(pos, life = life, rotation = rotation)
  jsonapi.apiEffectStrikeWave = proc(pos: Vec2, life: float32, rotation: float32) = effectStrikeWave(pos, life = life, rotation = rotation)

#region Procs copied to avoid circular dependency
proc getTexture(unit: Unit, name: string = ""): Texture =
  ## Loads a unit texture from the textures/ folder. Result is cached. Crashes if the texture isn't found!
  if not unit.textures.hasKey(name):
    let tex =
      if not unit.isModded:
        echo "Loading asset ", "textures/" & unit.name & name & ".png"
        loadTextureAsset("textures/" & unit.name & name & ".png")
      else:
        echo "Loading file ", unit.modPath / "unitSplashes" / unit.name & name & ".png"
        loadTextureFile(unit.modPath / "unitSplashes" / unit.name & name & ".png")
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
  for eval in [eval_x, eval_y]:
    # Functions
    # eval.addFunc("getScl", apiGetScl, 1)
    # eval.addFunc("hoverOffset", apiHoverOffset)
    eval.addFunc("px", apiPx, 1)
    # Constants
    eval.addVar("shadowOffset", 0.3f)
    eval.addVar("mapSize", mapSize)

  # Vector functions
  eval_x.addFunc("getScl", apiGetScl, 1)
  eval_y.addFunc("getScl", apiGetScl, 1)
  eval_x.addFunc("hoverOffset", apiHoverOffset_x, -1)
  eval_y.addFunc("hoverOffset", apiHoverOffset_y, -1)
  eval_x.addFunc("vec2", apiVec2_x, 2)
  eval_y.addFunc("vec2", apiVec2_y, 2)
  
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
  for e in [eval_x, eval_y]:
    e.addVar("state_secs", state.secs)
    e.addVar("state_lastSecs", state.lastSecs)
    e.addVar("state_time", state.time)
    e.addVar("state_rawBeat", state.rawBeat)
    e.addVar("state_moveBeat", state.moveBeat)
    e.addVar("state_newTurn", state.newTurn.float)
    e.addVar("state_hitTime", state.hitTime)
    e.addVar("state_healTime", state.healTime)
    e.addVar("state_points", state.points.float)
    e.addVar("state_turn", state.turn.float)
    e.addVar("state_hits", state.hits.float)
    e.addVar("state_totalHits", state.totalHits.float)
    e.addVar("state_misses", state.misses.float)
    e.addVar("state_currentBpm", state.currentBpm)

    e.addVar("fau_time", fau.time)

    if not state.map.isNil():
      e.addVar("beatSpacing", 1.0 / (state.currentBpm / 60.0))

  # Vector
  eval_x.addVar("_getScl", apigetScl_0())
  eval_y.addVar("_getScl", apiGetScl_0())
  eval_x.addVar("_hoverOffset", apiHoverOffset_x_0())
  eval_y.addVar("_hoverOffset", apiHoverOffset_y_0())
  
  eval_x.addVar("playerPos", state.playerPos.x.float)
  eval_y.addVar("playerPos", state.playerPos.y.float)

# Parses a JSON script into a sequence of procs
proc parseScript(drawStack: JsonNode): seq[proc()] =
  # Shortcuts
  template evalVec2(str: string): Vec2 = vec2(eval_x.eval(str), eval_y.eval(str))
  template evalVec2i(str: string): Vec2i = vec2i(eval_x.eval(str).int, eval_y.eval(str).int)
  template eval(str: string): float = eval_x.eval(str)
  template addEvalVar(name: string, val: string) =
    eval_x.addVar(name, eval_x.eval(val))
    eval_y.addVar(name, eval_y.eval(val))
  
  var procs = newSeq[proc()]()
  for elem in drawStack.getElems():
    let calledFunction = elem["type"].getStr()
    case calledFunction
    #region Setters
    of "SetFloat", "SetVec2":
      let
        name = elem["name"].getStr()
        value = elem["value"].getStr($elem["value"].getFloat())
      capture name, value: # This has to be done so the strings can be captured
        procs.add(proc() =
          eval_x.addVar(name, eval_x.eval(value))
          eval_y.addVar(name, eval_y.eval(value)))

    of "SetColor":
      let
        name = elem["name"].getStr()
        value = elem["value"].getStr()
      capture name, value:
        procs.add(proc() = colorTable[name] = getColor(value))
    #endregion

    #region Flow control
    of "Condition", "If": # if statement
      let
        condition = elem["condition"].getStr($elem["condition"].getFloat(elem["condition"].getBool().float))
        thenBody = parseScript(elem["then"])
        elseBody = (if not elem{"else"}.isNil: parseScript(elem["else"]) else: newSeq[proc()]())
      capture condition, thenBody, elseBody:
        procs.add(proc() =
          if not (eval(condition) == 0):
            for p in thenBody:
              p()
              if isBreaking or isReturning: return
          else:
            for p in elseBody:
              p()
              if isBreaking or isReturning: return
        )
    
    of "Iterate", "For": # For loop
      let
        iteratorName = elem["iterator"].getStr()
        startValue = elem["startValue"].getStr($elem["startValue"].getInt())
        endValue = elem["endValue"].getStr($elem["endValue"].getInt())
        body = parseScript(elem["body"])
      capture iteratorName, startValue, endValue, body:
        procs.add(proc() =
          var iter = eval(startValue).int
          let maxIter = eval(endValue).int

          block exitLoop:
            while true:
              eval_x.addVar(iteratorName, iter.float)
              eval_y.addVar(iteratorName, iter.float)
              for p in body:
                p()
                if isBreaking or isReturning: break exitLoop
              if iter >= maxIter: break
              iter += 1
          isBreaking = false
        )
    
    of "Repeat", "While": # While loop
      let
        condition = elem["condition"].getStr($elem["condition"].getFloat(elem["condition"].getBool().float))
        body = parseScript(elem["body"])
      capture condition, body:
        procs.add(proc() = 
          block exitLoop:
            while not (eval(condition) == 0):
              for p in body:
                p()
                if isBreaking or isReturning: break exitLoop
          isBreaking = false
        )
    
    of "Break":
      procs.add(proc() = isBreaking = true)
    
    of "Return":
      procs.add(proc() = isReturning = true)

    of "Formation", "ForEach":
      let
        formation = formations[elem["name"].getStr()]
        iter = elem["iterator"].getStr()
        body = parseScript(elem["body"])
      capture formation, iter, body:
        procs.add(proc() =
          block exitLoop:
            for v in formation:
              eval_x.addVar(iter, v.x.float)
              eval_y.addVar(iter, v.y.float)
              for p in body:
                p()
                if isBreaking or isReturning: break exitLoop
          isBreaking = false
        )

    of "Turns":
      let
        fromTurn = elem{"fromTurn"}.getStr($elem{"fromTurn"}.getInt(0))
        toTurn = elem{"toTurn"}.getStr($elem{"toTurn"}.getInt(high(int)))
        interval = elem{"interval"}.getStr($elem{"interval"}.getInt(1))
        progress = elem{"progress"}.getStr("")
        body = parseScript(elem["body"])
      capture fromTurn, toTurn, interval, progress, body:
        procs.add(proc() =
          let
            ft = eval(fromTurn)
            tt = eval(toTurn)
          if state.turn in ft..tt and (state.turn - ft) mod eval(interval) == 0:
            if progress != "":
              eval_x.addVar(progress, (state.turn + 1 - state.moveBeat - ft) / (tt + 1 - ft))
            for p in body:
              p()
              if isBreaking or isReturning: break
        )
    #endregion

    #region Patterns
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

    of "DrawRadLinesRound":
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

    of "DrawUnit":
      let
        pos = elem["pos"].getStr()
        scl = elem{"scl"}.getStr("1") # Same as "vec2(1, 1)" in this case
        color = elem{"color"}.getStr($colorWhite)
        part = elem{"part"}.getStr("")
      capture pos, scl, color, part:
        procs.add(proc() = currentUnit.getTexture(part).draw(evalVec2(pos), scl = evalVec2(scl), color = getColor(color)))
    #endregion

    #region Draw
    of "DrawFillQuadGradient":
      let
        v1 = elem["v1"].getStr()
        v2 = elem["v2"].getStr()
        v3 = elem["v3"].getStr()
        v4 = elem["v4"].getStr()
        c1 = elem["c1"].getStr()
        c2 = elem["c2"].getStr()
        c3 = elem["c3"].getStr()
        c4 = elem["c4"].getStr()
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture v1, v2, v3, v4, c1, c2, c3, c4, z:
        procs.add(proc() = fillQuad(evalVec2(v1), getColor(c1), evalVec2(v2), getColor(c2), evalVec2(v3), getColor(c3), evalVec2(v4), getColor(c4), eval(z)))
    
    of "DrawFillQuad":
      let 
        v1 = elem["v1"].getStr()
        v2 = elem["v2"].getStr()
        v3 = elem["v3"].getStr()
        v4 = elem["v4"].getStr()
        color = elem["color"].getStr()
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture v1, v2, v3, v4, color, z:
        procs.add(proc() = fillQuad(evalVec2(v1), evalVec2(v2), evalVec2(v3), evalVec2(v4), getColor(color), eval(z)))
    
    of "DrawFillRect":
      let 
        x = elem["x"].getStr($elem["x"].getFloat())
        y = elem["y"].getStr($elem["y"].getFloat())
        w = elem["w"].getStr($elem["w"].getFloat())
        h = elem["h"].getStr($elem["h"].getFloat())
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture x, y, w, h, color, z:
        procs.add(proc() = fillRect(eval(x), eval(y), eval(w), eval(h), getColor(color), eval(z)))
    
    of "DrawFillSquare":
      let 
        pos = elem["pos"].getStr()
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, radius, color, z:
        procs.add(proc() = fillSquare(evalVec2(pos), eval(radius), getColor(color), eval(z)))
    
    of "DrawFillTri":
      let
        v1 = elem["v1"].getStr()
        v2 = elem["v2"].getStr()
        v3 = elem["v3"].getStr()
        color = elem["color"].getStr()
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture v1, v2, v3, color, z:
        procs.add(proc() = fillTri(evalVec2(v1), evalVec2(v2), evalVec2(v3), getColor(color), eval(z)))
    
    of "DrawFillTriGradient":
      let
        v1 = elem["v1"].getStr()
        v2 = elem["v2"].getStr()
        v3 = elem["v3"].getStr()
        c1 = elem["c1"].getStr()
        c2 = elem["c2"].getStr()
        c3 = elem["c3"].getStr()
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture v1, v2, v3, c1, c2, c3, z:
        procs.add(proc() = fillTri(evalVec2(v1), evalVec2(v2), evalVec2(v3), getColor(c1), getColor(c2), getColor(c3), eval(z)))

    of "DrawFillCircle":
      let
        pos = elem["pos"].getStr()
        rad = elem["rad"].getStr($elem["rad"].getFloat())
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, rad, color, z:
        procs.add(proc() = fillCircle(evalVec2(pos), eval(rad), getColor(color), eval(z)))

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

    of "DrawFillLight":
      let
        pos = elem["pos"].getStr()
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        sides = elem{"sides"}.getStr($elem{"sides"}.getInt(20))
        centerColor = elem{"centerColor"}.getStr($colorWhite)
        edgeColor = elem{"edgeColor"}.getStr($colorClear)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, radius, sides, centerColor, edgeColor, z:
        procs.add(proc() = fillLight(evalVec2(pos), eval(radius), eval(sides).int, getColor(centerColor), getColor(edgeColor), eval(z)))

    of "DrawLine":
      let
        p1 = elem["p1"].getStr()
        p2 = elem["p2"].getStr()
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        square = elem{"square"}.getStr($elem{"square"}.getFloat(elem{"square"}.getBool(true).float))
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture p1, p2, stroke, color, square, z:
        procs.add(proc() = line(evalVec2(p1), evalVec2(p2), eval(stroke), getColor(color), eval(square) != 0, eval(z)))
    
    of "DrawLineAngle":
      let
        p = elem["p"].getStr()
        angle = elem["angle"].getStr($elem["angle"].getFloat())
        len = elem["len"].getStr($elem["len"].getFloat())
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        square = elem{"square"}.getStr($elem{"square"}.getFloat(elem{"square"}.getBool(true).float))
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture p, angle, len, stroke, color, square, z:
        procs.add(proc() = lineAngle(evalVec2(p), eval(angle), eval(len), eval(stroke), getColor(color), eval(square) != 0, eval(z)))
    
    of "DrawLineAngleCenter":
      let
        p = elem["p"].getStr()
        angle = elem["angle"].getStr($elem["angle"].getFloat())
        len = elem["len"].getStr($elem["len"].getFloat())
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        square = elem{"square"}.getStr($elem{"square"}.getFloat(elem{"square"}.getBool(true).float))
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture p, angle, len, stroke, color, square, z:
        procs.add(proc() = lineAngleCenter(evalVec2(p), eval(angle), eval(len), eval(stroke), getColor(color), eval(square) != 0, eval(z)))

    of "DrawLineRect":
      let
        pos = elem["pos"].getStr()
        size = elem["size"].getStr()
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
        margin = elem{"margin"}.getStr($elem{"margin"}.getFloat(0f))
      capture pos, size, stroke, color, z, margin:
        procs.add(proc() = lineRect(evalVec2(pos), evalVec2(size), eval(stroke), getColor(color), eval(z), eval(margin)))
    
    of "DrawLineSquare":
      let 
        pos = elem["pos"].getStr()
        rad = elem["rad"].getStr($elem["rad"].getFloat())
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, rad, stroke, color, z:
        procs.add(proc() = lineSquare(evalVec2(pos), eval(rad), eval(stroke), getColor(color), eval(z)))

    of "DrawRadLines":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        len = elem["len"].getStr($elem["len"].getFloat())
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, sides, radius, len, stroke, rotation, color, z:
        procs.add(proc() = spikes(evalVec2(pos), eval(sides).int, eval(radius), eval(len), eval(stroke), eval(rotation), getColor(color), eval(z)))
    
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

    of "DrawArcRadius":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        angleFrom = elem["angleFrom"].getStr($elem["angleFrom"].getFloat())
        angleTo = elem["angleTo"].getStr($elem["angleTo"].getFloat())
        radiusFrom = elem["radiusFrom"].getStr($elem["radiusFrom"].getFloat())
        radiusTo = elem["radiusTo"].getStr($elem["radiusTo"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, sides, angleFrom, angleTo, radiusFrom, radiusTo, rotation, color, z:
        procs.add(proc() = arcRadius(evalVec2(pos), eval(sides).int, eval(angleFrom), eval(angleTo), eval(radiusFrom), eval(radiusTo), eval(rotation), getColor(color), eval(z)))

    of "DrawArc":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        angleFrom = elem["angleFrom"].getStr($elem["angleFrom"].getFloat())
        angleTo = elem["angleTo"].getStr($elem["angleTo"].getFloat())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, sides, angleFrom, angleTo, radius, rotation, stroke, color, z:
        procs.add(proc() = arc(evalVec2(pos), eval(sides).int, eval(angleFrom), eval(angleTo), eval(radius), eval(rotation), eval(stroke), getColor(color), eval(z)))
    
    of "DrawCrescent":
      let
        pos = elem["pos"].getStr()
        sides = elem["sides"].getStr($elem["sides"].getInt())
        angleFrom = elem["angleFrom"].getStr($elem["angleFrom"].getFloat())
        angleTo = elem["angleTo"].getStr($elem["angleTo"].getFloat())
        radius = elem["radius"].getStr($elem["radius"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture pos, sides, angleFrom, angleTo, radius, rotation, stroke, color, z:
        procs.add(proc() = crescent(evalVec2(pos), eval(sides).int, eval(angleFrom), eval(angleTo), eval(radius), eval(rotation), eval(stroke), getColor(color), eval(z)))

    of "DrawShape":
      let
        points = elem["points"].getElems().map(proc(x: JsonNode): string = x.getStr())
        wrap = elem{"wrap"}.getStr($elem{"wrap"}.getFloat(elem{"wrap"}.getBool(false).float))
        stroke = elem{"stroke"}.getStr($elem{"stroke"}.getFloat(1f.px))
        color = elem{"color"}.getStr($colorWhite)
        z = elem{"z"}.getStr($elem{"z"}.getFloat(0f))
      capture points, wrap, stroke, color, z:
        procs.add(proc() =
          var vecs = points.map(proc(x: string): Vec2 = evalVec2(x))
          poly(vecs, eval(wrap) != 0, eval(stroke), getColor(color), eval(z))
        )

    
    of "DrawBloom": # contains a body, so recurse
      let body = parseScript(elem["body"])
      capture body:
        procs.add(proc() =
          drawBloom:
            for p in body:
              p()
        )
    #endregion
    
    #region Ability
    of "MakeWall":
      let
        pos = elem["pos"].getStr()
        sprite = elem{"sprite"}.getStr("wall")
        life = elem{"life"}.getStr($elem{"life"}.getInt(10))
        health = elem{"health"}.getStr($elem{"health"}.getInt(3))
      capture pos, sprite, life, health:
        procs.add(proc() = apiMakeWall(evalVec2i(pos), sprite, eval(life).int, eval(health).int))

    of "DamageBlocks":
      let target = elem["target"].getStr()
      capture target:
        procs.add(proc() =
          apiDamageBlocks(evalVec2i(target))
        )
    #endregion

    #region Makers
    of "MakeDelay":
      let
        delay = elem{"delay"}.getStr($elem{"delay"}.getInt(0))
        callback = parseScript(elem["callback"])
      capture delay, callback:
        procs.add(proc() = apiMakeDelay(eval(delay).int, proc() =
          for p in callback:
            p()
            if isBreaking or isReturning: break
          isBreaking = false))
    
    of "MakeBullet":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
        tex = elem{"tex"}.getStr("bullet")
      capture pos, dir, tex:
        procs.add(proc() = apiMakeBullet(evalVec2i(pos), evalVec2i(dir), tex))
    
    of "MakeTimedBullet":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
        tex = elem{"tex"}.getStr("bullet")
        life = elem{"life"}.getStr($elem{"life"}.getInt(3))
      capture pos, dir, tex, life:
        procs.add(proc() = apiMakeTimedBullet(evalVec2i(pos), evalVec2i(dir), tex, eval(life).int))
    
    of "MakeConveyor":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
        length = elem{"length"}.getStr($elem{"length"}.getInt(2))
        tex = elem{"tex"}.getStr("conveyor")
        gen = elem{"gen"}.getStr($elem{"gen"}.getInt(0))
      capture pos, dir, tex:
        procs.add(proc() = apiMakeConveyor(evalVec2i(pos), evalVec2i(dir), eval(length).int, tex, eval(gen).int))
    
    of "MakeLaserSegment":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
      capture pos, dir:
        procs.add(proc() = apiMakeLaserSegment(evalVec2i(pos), evalVec2i(dir)))

    of "MakeRouter":
      let
        pos = elem["pos"].getStr()
        length = elem{"length"}.getStr($elem{"length"}.getInt(2))
        life = elem{"life"}.getStr($elem{"life"}.getInt(2))
        diag = elem{"diag"}.getStr($elem{"diag"}.getFloat(elem{"diag"}.getBool(false).float))
        tex = elem{"tex"}.getStr("router")
        allDir = elem{"allDir"}.getStr($elem{"allDir"}.getFloat(elem{"allDir"}.getBool(false).float))
      capture pos, length, life, diag, tex, allDir:
        procs.add(proc() = apiMakeRouter(evalVec2i(pos), eval(length).int, eval(life).int, eval(diag) != 0, tex, eval(allDir) != 0))

    of "MakeSorter":
      let
        pos = elem["pos"].getStr()
        mdir = elem["mdir"].getStr()
        moveSpace = elem{"moveSpace"}.getStr($elem{"moveSpace"}.getInt(2))
        spawnSpace = elem{"spawnSpace"}.getStr($elem{"spawnSpace"}.getInt(2))
        length = elem{"length"}.getStr($elem{"length"}.getInt(1))
      capture pos, mdir, moveSpace, spawnSpace, length:
        procs.add(proc() = apiMakeSorter(evalVec2i(pos), evalVec2i(mdir), eval(moveSpace).int, eval(spawnSpace).int, eval(length).int))

    of "MakeTurret":
      let
        pos = elem["pos"].getStr()
        face = elem["face"].getStr()
        reload = elem{"reload"}.getStr($elem{"reload"}.getInt(4))
        life = elem{"life"}.getStr($elem{"life"}.getInt(8))
        tex = elem{"tex"}.getStr("duo")
      capture pos, face, reload, life, tex:
        procs.add(proc() = apiMakeTurret(evalVec2i(pos), evalVec2i(face), eval(reload).int, eval(life).int, tex))

    of "MakeArc":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
        tex = elem{"tex"}.getStr("arc")
        bounces = elem{"bounces"}.getStr($elem{"bounces"}.getInt(1))
        life = elem{"life"}.getStr($elem{"life"}.getInt(3))
      capture pos, dir, tex, bounces, life:
         procs.add(proc() = apiMakeArc(evalVec2i(pos), evalVec2i(dir), tex, eval(bounces).int, eval(life).int))

    of "MakeDelayBullet":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
        tex = elem{"tex"}.getStr()
      capture pos, dir, tex:
        procs.add(proc() = apiMakeDelayBullet(evalVec2i(pos), evalVec2i(dir), tex))

    of "MakeDelayBulletWarn":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
        tex = elem{"tex"}.getStr()
      capture pos, dir, tex:
        procs.add(proc() = apiMakeDelayBulletWarn(evalVec2i(pos), evalVec2i(dir), tex))

    of "MakeBulletCircle":
      let
        pos = elem["pos"].getStr()
        tex = elem{"tex"}.getStr()
      capture pos, tex:
        procs.add(proc() = apiMakeBulletCircle(evalVec2i(pos), tex))

    of "MakeLaser":
      let
        pos = elem["pos"].getStr()
        dir = elem["dir"].getStr()
      capture pos, dir:
        procs.add(proc() = apiMakeLaser(evalVec2i(pos), evalVec2i(dir)))
    #endregion

    #region Other
    of "MixColor":
      let
        name = elem["name"].getStr()
        mode = elem{"mode"}.getStr("mix")
        col1 = elem["col1"].getStr()
        col2 = elem{"col2"}.getStr($colorClear)
        factor = elem{"factor"}.getStr($elem{"factor"}.getFloat(1))
      capture name, mode, col1, col2, factor:
        case mode
        of "add":
          procs.add(proc() =
            let c1 = getColor(col1)
            colorTable[name] = c1.mix(c1 + getColor(col2), eval(factor))
          )
        of "sub":
          procs.add(proc() =
            let
              c1 = getColor(col1)
              c2 = getColor(col2)
            colorTable[name] = c1.mix(rgba(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b, c1.a - c2.a), eval(factor))
          )
        of "mul":
          procs.add(proc() =
            let c1 = getColor(col1)
            colorTable[name] = c1.mix(c1 * getColor(col2), eval(factor))
          )
        of "div":
          procs.add(proc() =
            let c1 = getColor(col1)
            colorTable[name] = c1.mix(c1 / getColor(col2), eval(factor))
          )
        of "and":
          procs.add(proc() =
            let c1 = getColor(col1)
            var c2 = getColor(col2)
            c2.rv = c1.rv and c2.rv
            c2.gv = c1.gv and c2.gv
            c2.bv = c1.bv and c2.bv
            c2.av = c1.av and c2.av
            colorTable[name] = c1.mix(c2, eval(factor))
          )
        of "or":
          procs.add(proc() =
            let c1 = getColor(col1)
            var c2 = getColor(col2)
            c2.rv = c1.rv or c2.rv
            c2.gv = c1.gv or c2.gv
            c2.bv = c1.bv or c2.bv
            c2.av = c1.av or c2.av
            colorTable[name] = c1.mix(c2, eval(factor))
          )
        of "xor":
          procs.add(proc() =
            let c1 = getColor(col1)
            var c2 = getColor(col2)
            c2.rv = c1.rv xor c2.rv
            c2.gv = c1.gv xor c2.gv
            c2.bv = c1.bv xor c2.bv
            c2.av = c1.av xor c2.av
            colorTable[name] = c1.mix(c2, eval(factor))
          )
        of "not":
          procs.add(proc() =
            let c1 = getColor(col1)
            var c2 = c1
            c2.rv = not c2.rv
            c2.gv = not c2.gv
            c2.bv = not c2.bv
            c2.av = not c2.av
            colorTable[name] = c1.mix(c2, eval(factor))
          )
        else: # If not valid then mix
          procs.add(proc() = colorTable[name] = getColor(col1).mix(getColor(col2), eval(factor)))

    of "ChangeBPM":
      let bpm = elem["bpm"].getStr($elem["bpm"].getFloat())
      capture bpm:
        procs.add(proc() =
          state.currentBpm = eval(bpm)
          let
            baseTime = 60.0 / state.map.bpm
            curTime = 60.0 / state.currentBpm
            baseTurn = state.secs / baseTime
          state.turnOffset = (baseTime - curTime) * baseTurn / curTime + baseTurn - state.turn
        )
    #endregion

    #region Effects
    of "EffectExplode":
      let pos = elem["pos"].getStr()
      capture pos:
        procs.add(proc() = apiEffectExplode(evalVec2(pos)))

    of "EffectExplodeHeal":
      let pos = elem["pos"].getStr()
      capture pos:
        procs.add(proc() = apiEffectExplodeHeal(evalVec2(pos)))

    of "EffectWarn":
      let
        pos = elem["pos"].getStr()
        life = elem["life"].getStr($elem["life"].getFloat())
      capture pos, life:
        procs.add(proc() = apiEffectWarn(evalVec2(pos), eval(life)))

    of "EffectWarnBullet":
      let
        pos = elem["pos"].getStr()
        life = elem["life"].getStr($elem["life"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
      capture pos, life, rotation:
        procs.add(proc() = apiEffectWarnBullet(evalVec2(pos), eval(life), eval(rotation)))

    of "EffectStrikeWave":
      let
        pos = elem["pos"].getStr()
        life = elem["life"].getStr($elem["life"].getFloat())
        rotation = elem{"rotation"}.getStr($elem{"rotation"}.getFloat(0f))
      capture pos, life, rotation:
        procs.add(proc() = apiEffectStrikeWave(evalVec2(pos), eval(life), eval(rotation)))
    #endregion

    #region Custom procedures
    else:
      let
        procName: string = (
          if "::" notin calledFunction: currentNamespace & "::" & calledFunction
          else: calledFunction
        )
        fields = elem.getFields()

      # convert [string, JsonNode] to [string, string]
      var
        parameters: Table[string, string]
        # floats: Table[string, string]
        # colors: Table[string, string]
      for key, val in fields:
      # for key, val in fields:
        if key == "type": continue # ignore type

        # Unknown data type, so try all of them
        let str = val.getStr($val.getFloat(val.getBool().float))

        parameters[key] = str
        # # Differentiate between color and float
        # if str.startsWith('#') or str in colorTable:
        #   echo str, " in colorTable"
        #   colors[key] = str
        # else:
        #   echo str, " not in colorTable"
        #   floats[key] = str

      # Cannot use capture because of generic table
      # See https://forum.nim-lang.org/t/10887#72561 for more information
      # capture procName, colors, floats:
      (proc(procName: string, parameters: Table[string, string]) =
        procs.add(proc() =
          if procName in procedures:
            let p = procedures[procName]

            # Add parameters
            for k, v in p.defaultValues:
              if v.startsWith('#') or v in colorTable:
                colorTable[k] = getColor(v)
              else:
                addEvalVar(k, v)
            for k, v in parameters:
              if v.startsWith('#') or v in colorTable:
                colorTable[k] = getColor(v)
              else:
                addEvalVar(k, v)

            # Add color parameters
            # for k, v in p.defaultColors:
            #   colorTable[k] = getColor(v)
            # for k, v in colors:
            #   colorTable[k] = getColor(v)

            # Execute script
            p.script()
        )
      )(procName, parameters)
    #endregion

  return procs

# Returns a proc for drawing a unit splash
proc getUnitDraw*(drawStack: JsonNode): (proc(unit: Unit, basePos: Vec2)) =
  var procs = parseScript(drawStack)
  
  capture procs:
    return (proc(unit: Unit, basePos: Vec2) =
      updateEvals()

      # Additional updates to eval
      currentUnit = unit
      eval_x.addVar("basePos", basePos.x)
      eval_y.addVar("basePos", basePos.y)

      # execute
      for p in procs:
        p()
        if isBreaking or isReturning: break
      isBreaking = false
      isReturning = false
    )

proc getUnitAbility*(script: JsonNode): (proc(entity: EntityRef, moves: int)) =
  var procs = parseScript(script)

  capture procs:
    isBreaking = false
    isReturning = false
    return (proc(entity: EntityRef, moves: int) =
      updateEvals()

      # Additional updates to eval
      let
        gridPosition = fetchGridPosition(entity)
        lastMove = fetchLastMove(entity)
      currentEntityRef = entity
      eval_x.addVar("moves", moves.float)
      eval_y.addVar("moves", moves.float)
      eval_x.addVar("gridPosition", gridPosition.x.float)
      eval_y.addVar("gridPosition", gridPosition.y.float)
      eval_x.addVar("lastMove", lastMove.x.float)
      eval_y.addVar("lastMove", lastMove.y.float)

      for p in procs:
        p()
        if isBreaking or isReturning: break
      isBreaking = false
      isReturning = false
    )

proc getScript*(script: JsonNode, update = true): (proc()) =
  var procs = parseScript(script)

  capture procs, update:
    return (proc() =
      if update:
        updateEvals()
      for p in procs:
        p()
        if isBreaking or isReturning: break
      isBreaking = false
      isReturning = false
    )
