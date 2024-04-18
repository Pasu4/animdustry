import fau/fmath, pkg/polymorph
import sequtils, tables

let
  formations* = {
    "d4": d4.toSeq(),
    "d4mid": d4mid.toSeq(),
    "d4edge": d4edge.toSeq(),
    "d8": d8.toSeq(),
    "d8mid": d8mid.toSeq()
  }.toTable

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

  apivars.apiMakeDelayBullet      = proc(pos, dir: Vec2i, tex = "") = delayBullet(pos, dir, tex)
  apivars.apiMakeDelayBulletWarn  = proc(pos, dir: Vec2i, tex = "") = delayBulletWarn(pos, dir, tex)
  apivars.apiMakeBulletCircle     = proc(pos: Vec2i,      tex = "") = bulletCircle(pos, tex)
  apivars.apiMakeLaser            = proc(pos, dir: Vec2i)           = laser(pos, dir)

  # Other
  apivars.apiAddPoints = addPoints
  apivars.apiDamageBlocks = damageBlocks

  # Effects (evil post-compile-time signature apparently)
  apivars.apiEffectExplode = proc(pos: Vec2) = effectExplode(pos)
  apivars.apiEffectExplodeHeal = proc(pos: Vec2) = effectExplodeHeal(pos)
  apivars.apiEffectWarn = proc(pos: Vec2, life: float32) = effectWarn(pos, life = life)
  apivars.apiEffectWarnBullet = proc(pos: Vec2, life: float32, rotation: float32) = effectWarnBullet(pos, life = life, rotation = rotation)
  apivars.apiEffectStrikeWave = proc(pos: Vec2, life: float32, rotation: float32) = effectStrikeWave(pos, life = life, rotation = rotation)
  
template drawBloom*(body: untyped) =
  drawBloomA()
  body
  drawBloomB()
