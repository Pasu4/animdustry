import sequtils, tables
import core, fau/[fmath, color], pkg/polymorph
import types

let
  formations* = {
    "d4": d4.toSeq(),
    "d4mid": d4mid.toSeq(),
    "d4edge": d4edge.toSeq(),
    "d8": d8.toSeq(),
    "d8mid": d8mid.toSeq()
  }.toTable

var
  customTextures*: Table[string, Texture]       # Custom textures for bullets, enemies, etc.
  currentNamespace*: string                     # For loading custom textures (LEGACY: resolving procedures)

  currentUnit*: Unit                            # The current unit
  currentEntityRef*: EntityRef                  # The current EntityRef (for abilityProc)

var
  # Procs from main
  # I unfortunately see no better way to do this.
  drawBloomA*, drawBloomB*: proc() # Draws bloom (it's unfortunate but what can you do)

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
  apiMakeCustomEntity*: proc(id: int, pos: Vec2i, script: proc(state: CustomEntityState): CustomEntityState, lifetime = -1, destructible = false, damagePlayer = false, deleteOnContact = false)

  apiMakeDelayBullet*: proc(pos, dir: Vec2i, tex = "")
  apiMakeDelayBulletWarn*: proc(pos, dir: Vec2i, tex = "")
  apiMakeBulletCircle*: proc(pos: Vec2i, tex = "")
  apiMakeLaser*: proc(pos, dir: Vec2i)

  apiAddPoints*: proc(amount = 1)
  apiDamageBlocks*: proc(target: Vec2i)
  apiImportCustomTexture*: proc(sourceName: string, sourceNamespace: string, targetName: string, targetNamespace: string)

  #apiEffectExplode*: proc(pos: Vec2, rotation = 0.0'f32, color = colorWhite, life = 0.4'f32, size = 0.0'f32, parent = NO_ENTITY_REF)
  apiEffectExplode*: proc(pos: Vec2)
  apiEffectExplodeHeal*: proc(pos: Vec2)
  # apiEffectLaserShoot*: proc()
  apiEffectWarn*: proc(pos: Vec2, life: float32)
  apiEffectWarnBullet*: proc(pos: Vec2, life: float32, rotation: float32 = 0.0)
  apiEffectStrikeWave*: proc(pos: Vec2, life: float32, rotation: float32 = 0.0)

  apiGetTexture*: proc(unit: Unit, name: string = ""): Texture
  apiMusicTime*: proc(): float

# Export bloom procs
proc exportBloom*(bloomA: proc(), bloomB: proc()) =
  # Set bloom procs
  # For whatever reason, sysDraw only exists within main
  drawBloomA = bloomA
  drawBloomB = bloomB

# Export main's procs to the API
template exportProcs* =

  # Fetch
  apivars.fetchGridPosition = proc(entity: EntityRef): Vec2i = entity.fetch(GridPos).vec
  apivars.fetchLastMove = proc(entity: EntityRef): Vec2i = entity.fetch(Input).lastMove

  # Makers
  apivars.apiMakeDelay        = makeDelay
  apivars.apiMakeBullet       = makeBullet
  apivars.apiMakeTimedBullet  = makeTimedBullet
  apivars.apiMakeConveyor     = makeConveyor
  apivars.apiMakeLaserSegment = makeLaser
  apivars.apiMakeRouter       = makeRouter
  apivars.apiMakeSorter       = makeSorter
  apivars.apiMakeTurret       = makeTurret
  apivars.apiMakeArc          = makeArc
  apivars.apiMakeWall         = makeWall
  apivars.apiMakeCustomEntity = makeCustomEntity

  apivars.apiMakeDelayBullet      = proc(pos, dir: Vec2i, tex = "") = delayBullet(pos, dir, tex)
  apivars.apiMakeDelayBulletWarn  = proc(pos, dir: Vec2i, tex = "") = delayBulletWarn(pos, dir, tex)
  apivars.apiMakeBulletCircle     = proc(pos: Vec2i,      tex = "") = bulletCircle(pos, tex)
  apivars.apiMakeLaser            = proc(pos, dir: Vec2i)           = laser(pos, dir)

  # Other
  apivars.apiAddPoints = addPoints
  apivars.apiDamageBlocks = damageBlocks
  apivars.apiImportCustomTexture = importCustomTexture

  # Effects (evil post-compile-time signature apparently)
  apivars.apiEffectExplode = proc(pos: Vec2) = effectExplode(pos)
  apivars.apiEffectExplodeHeal = proc(pos: Vec2) = effectExplodeHeal(pos)
  apivars.apiEffectWarn = proc(pos: Vec2, life: float32) = effectWarn(pos, life = life)
  apivars.apiEffectWarnBullet = proc(pos: Vec2, life: float32, rotation: float32) = effectWarnBullet(pos, life = life, rotation = rotation)
  apivars.apiEffectStrikeWave = proc(pos: Vec2, life: float32, rotation: float32) = effectStrikeWave(pos, life = life, rotation = rotation)

  apivars.apiGetTexture = getTexture
  apivars.apiMusicTime = musicTime
  
template drawBloom*(body: untyped) =
  drawBloomA()
  body
  drawBloomB()

proc apiMixColor*(col1, col2: Color, alpha: float32, mode: string = "mix"): Color =
  case mode
  of "add":
    return col1.mix(col1 + col2, alpha)
  of "sub":
    return col1.mix(rgba(col1.r - col2.r, col1.g - col2.g, col1.b - col2.b, col1.a - col2.a), alpha)
  of "mul":
    return col1.mix(col1 * col2, alpha)
  of "div":
    return col1.mix(col1 / col2, alpha)
  of "and":
    var c2 = col2
    c2.rv = col1.rv and col2.rv
    c2.gv = col1.gv and col2.gv
    c2.bv = col1.bv and col2.bv
    c2.av = col1.av and col2.av
    return col1.mix(c2, alpha)
  of "or":
    var c2 = col2
    c2.rv = col1.rv or col2.rv
    c2.gv = col1.gv or col2.gv
    c2.bv = col1.bv or col2.bv
    c2.av = col1.av or col2.av
    return col1.mix(c2, alpha)
  of "xor":
    var c2 = col2
    c2.rv = col1.rv xor col2.rv
    c2.gv = col1.gv xor col2.gv
    c2.bv = col1.bv xor col2.bv
    c2.av = col1.av xor col2.av
    return col1.mix(c2, alpha)
  of "not":
    var c2 = col1
    c2.rv = not col1.rv
    c2.gv = not col1.gv
    c2.bv = not col1.bv
    c2.av = not col1.av
    return col1.mix(c2, alpha)
  else: # If not valid then mix
    return col1.mix(col2, alpha)

#region Procs copied to avoid circular dependency
# proc getTexture*(unit: Unit, name: string = ""): Texture =
#   ## Loads a unit texture from the textures/ folder. Result is cached. Crashes if the texture isn't found!
#   if not unit.textures.hasKey(name):
#     let tex =
#       if not unit.isModded:
#         echo "Loading asset ", "textures/" & unit.name & name & ".png"
#         loadTextureAsset("textures/" & unit.name & name & ".png")
#       else:
#         echo "Loading file ", unit.modPath / "unitSplashes" / unit.name & name & ".png"
#         loadTextureFile(unit.modPath / "unitSplashes" / unit.name & name & ".png")
#     tex.filter = tfLinear
#     unit.textures[name] = tex
#     return tex
#   return unit.textures[name]

# proc musicTime*(): float = state.secs

#endregion
