// Functions and classes in this file are only for highlighting purposes.
// This file is not to be executed by the mod loader.
// The file name should be "__api.js" to be ignored by the mod loader.

//#region Values

/**
 * The maximum coordinate of a tile. The top-rightmost tile has the coordinate *(mapSize, mapSize)*.
 * @type {int}
 */
const mapSize = 6;

/**
 * The standard offset of a unit's shadow. Used for drawing unit splashes.
 * @type {Vec2}
 */
const shadowOffset = new Vec2(0.3);

/**
 * Contains directional vectors in all four cardinal directions.
 * @type {Vec2[]}
 */
const d4 = [new Vec2(0)]; // placeholder
/**
 * Contains directional vectors in all four cardinal directions plus the middle.
 * @type {Vec2[]}
 */
const d4mid = [new Vec2(0)]; // placeholder
/**
 * Contains directional vectors in all four diagonal directions.
 * @type {Vec2[]}
 */
const d4edge = [new Vec2(0)]; // placeholder
/**
 * Contains directional vectors in all diagonal and cardinal directions.
 * @type {Vec2[]}
 */
const d8 = [new Vec2(0)]; // placeholder
/**
 * Contains directional vectors in all diagonal and cardinal directions plus the middle.
 * @type {Vec2[]}
 */
const d8mid = [new Vec2(0)]; // placeholder

//#endregion

//#region Sprites

/**
 * Contains all the default sprites used in the game.
 * @hideconstructor
 */
class Sprites {
    /**
     * @default "arrow"
     * @readonly
     * @type {string}
     */
    static arrow;
    /**
     * @default "beach"
     * @readonly
     * @type {string}
     */
    static beach;
    /**
     * @default "big-copper"
     * @readonly
     * @type {string}
     */
    static bigCopper;
    /**
     * @default "circle"
     * @readonly
     * @type {string}
     */
    static circle;
    /**
     * @default "ckat"
     * @readonly
     * @type {string}
     */
    static ckat;
    /**
     * @default "cloud1"
     * @readonly
     * @type {string}
     */
    static cloud1;
    /**
     * @default "cloud2"
     * @readonly
     * @type {string}
     */
    static cloud2;
    /**
     * @default "cloud3"
     * @readonly
     * @type {string}
     */
    static cloud3;
    /**
     * @default "cloud4"
     * @readonly
     * @type {string}
     */
    static cloud4;
    /**
     * @default "empty"
     * @readonly
     * @type {string}
     */
    static empty;
    /**
     * @default "error"
     * @readonly
     * @type {string}
     */
    static error;
    /**
     * @default "explode0"
     * @readonly
     * @type {string}
     */
    static explode0;
    /**
     * @default "explode1"
     * @readonly
     * @type {string}
     */
    static explode1;
    /**
     * @default "explode2"
     * @readonly
     * @type {string}
     */
    static explode2;
    /**
     * @default "explode3"
     * @readonly
     * @type {string}
     */
    static explode3;
    /**
     * @default "explode4"
     * @readonly
     * @type {string}
     */
    static explode4;
    /**
     * @default "hit0"
     * @readonly
     * @type {string}
     */
    static hit0;
    /**
     * @default "hit1"
     * @readonly
     * @type {string}
     */
    static hit1;
    /**
     * @default "hit2"
     * @readonly
     * @type {string}
     */
    static hit2;
    /**
     * @default "hit3"
     * @readonly
     * @type {string}
     */
    static hit3;
    /**
     * @default "hit4"
     * @readonly
     * @type {string}
     */
    static hit4;
    /**
     * @default "hit5"
     * @readonly
     * @type {string}
     */
    static hit5;
    /**
     * @default "laser"
     * @readonly
     * @type {string}
     */
    static laser;
    /**
     * @default "longcloud1"
     * @readonly
     * @type {string}
     */
    static longcloud1;
    /**
     * @default "longcloud2"
     * @readonly
     * @type {string}
     */
    static longcloud2;
    /**
     * @default "longcloud3"
     * @readonly
     * @type {string}
     */
    static longcloud3;
    /**
     * @default "longcloud4"
     * @readonly
     * @type {string}
     */
    static longcloud4;
    /**
     * @default "longcloud5"
     * @readonly
     * @type {string}
     */
    static longcloud5;
    /**
     * @default "petal"
     * @readonly
     * @type {string}
     */
    static petal;
    /**
     * @default "reload"
     * @readonly
     * @type {string}
     */
    static reload;
    /**
     * @default "shadow"
     * @readonly
     * @type {string}
     */
    static shadow;
    /**
     * @default "smoke0"
     * @readonly
     * @type {string}
     */
    static smoke0;
    /**
     * @default "smoke1"
     * @readonly
     * @type {string}
     */
    static smoke1;
    /**
     * @default "smoke2"
     * @readonly
     * @type {string}
     */
    static smoke2;
    /**
     * @default "smoke3"
     * @readonly
     * @type {string}
     */
    static smoke3;
    /**
     * @default "smoke4"
     * @readonly
     * @type {string}
     */
    static smoke4;
    /**
     * @default "smoke5"
     * @readonly
     * @type {string}
     */
    static smoke5;
    /**
     * @default "star1"
     * @readonly
     * @type {string}
     */
    static star1;
    /**
     * @default "star2"
     * @readonly
     * @type {string}
     */
    static star2;
    /**
     * @default "star3"
     * @readonly
     * @type {string}
     */
    static star3;
    /**
     * @default "sun"
     * @readonly
     * @type {string}
     */
    static sun;
    /**
     * @default "tile"
     * @readonly
     * @type {string}
     */
    static tile;
    /**
     * @default "wall"
     * @readonly
     * @type {string}
     */
    static wall;

    /**
     * @default "arc"
     * @readonly
     * @type {string}
     */
    static arc;
    /**
     * @default "book"
     * @readonly
     * @type {string}
     */
    static book;
    /**
     * @default "bullet-blue"
     * @readonly
     * @type {string}
     */
    static bulletBlue;
    /**
     * @default "bullet-pink"
     * @readonly
     * @type {string}
     */
    static bulletPink;
    /**
     * @default "bullet-purple"
     * @readonly
     * @type {string}
     */
    static bulletPurple;
    /**
     * @default "bullet-tri"
     * @readonly
     * @type {string}
     */
    static bulletTri;
    /**
     * @default "bullet"
     * @readonly
     * @type {string}
     */
    static bullet;
    /**
     * @default "conveyor"
     * @readonly
     * @type {string}
     */
    static conveyor;
    /**
     * @default "copper"
     * @readonly
     * @type {string}
     */
    static copper;
    /**
     * @default "duo"
     * @readonly
     * @type {string}
     */
    static duo;
    /**
     * @default "fail"
     * @readonly
     * @type {string}
     */
    static fail;
    /**
     * @default "headphones"
     * @readonly
     * @type {string}
     */
    static headphones;
    /**
     * @default "health"
     * @readonly
     * @type {string}
     */
    static health;
    /**
     * @default "info"
     * @readonly
     * @type {string}
     */
    static info;
    /**
     * @default "junction"
     * @readonly
     * @type {string}
     */
    static junction;
    /**
     * @default "lancer"
     * @readonly
     * @type {string}
     */
    static lancer;
    /**
     * @default "lancer2"
     * @readonly
     * @type {string}
     */
    static lancer2;
    /**
     * @default "mine"
     * @readonly
     * @type {string}
     */
    static mine;
    /**
     * @default "overflow-gate"
     * @readonly
     * @type {string}
     */
    static overflowGate;
    /**
     * @default "pause"
     * @readonly
     * @type {string}
     */
    static pause;
    /**
     * @default "play"
     * @readonly
     * @type {string}
     */
    static play;
    /**
     * @default "progress-tick"
     * @readonly
     * @type {string}
     */
    static progressTick;
    /**
     * @default "progress"
     * @readonly
     * @type {string}
     */
    static progress;
    /**
     * @default "router"
     * @readonly
     * @type {string}
     */
    static router;
    /**
     * @default "settings"
     * @readonly
     * @type {string}
     */
    static settings;
    /**
     * @default "shield"
     * @readonly
     * @type {string}
     */
    static shield;
    /**
     * @default "skat"
     * @readonly
     * @type {string}
     */
    static skat;
    /**
     * @default "sorter"
     * @readonly
     * @type {string}
     */
    static sorter;
    /**
     * @default "unit-alpha-happy"
     * @readonly
     * @type {string}
     */
    static unitAlphaHappy;
    /**
     * @default "unit-alpha-hit"
     * @readonly
     * @type {string}
     */
    static unitAlphaHit;
    /**
     * @default "unit-alpha"
     * @readonly
     * @type {string}
     */
    static unitAlpha;
    /**
     * @default "unit-boulder-hit"
     * @readonly
     * @type {string}
     */
    static unitBoulderHit;
    /**
     * @default "unit-boulder"
     * @readonly
     * @type {string}
     */
    static unitBoulder;
    /**
     * @default "unit-crawler-angery"
     * @readonly
     * @type {string}
     */
    static unitCrawlerAngery;
    /**
     * @default "unit-crawler-hit"
     * @readonly
     * @type {string}
     */
    static unitCrawlerHit;
    /**
     * @default "unit-crawler"
     * @readonly
     * @type {string}
     */
    static unitCrawler;
    /**
     * @default "unit-mono-happy"
     * @readonly
     * @type {string}
     */
    static unitMonoHappy;
    /**
     * @default "unit-mono-hit"
     * @readonly
     * @type {string}
     */
    static unitMonoHit;
    /**
     * @default "unit-mono"
     * @readonly
     * @type {string}
     */
    static unitMono;
    /**
     * @default "unit-oct-angery"
     * @readonly
     * @type {string}
     */
    static unitOctAngery;
    /**
     * @default "unit-oct-hit"
     * @readonly
     * @type {string}
     */
    static unitOctHit;
    /**
     * @default "unit-oct"
     * @readonly
     * @type {string}
     */
    static unitOct;
    /**
     * @default "unit-oxynoe-hit"
     * @readonly
     * @type {string}
     */
    static unitOxynoeHit;
    /**
     * @default "unit-oxynoe"
     * @readonly
     * @type {string}
     */
    static unitOxynoe;
    /**
     * @default "unit-quad-hit"
     * @readonly
     * @type {string}
     */
    static unitQuadHit;
    /**
     * @default "unit-quad"
     * @readonly
     * @type {string}
     */
    static unitQuad;
    /**
     * @default "unit-sei-hit"
     * @readonly
     * @type {string}
     */
    static unitSeiHit;
    /**
     * @default "unit-sei"
     * @readonly
     * @type {string}
     */
    static unitSei;
    /**
     * @default "unit-zenith-angery"
     * @readonly
     * @type {string}
     */
    static unitZenithAngery;
    /**
     * @default "unit-zenith-hit"
     * @readonly
     * @type {string}
     */
    static unitZenithHit;
    /**
     * @default "unit-zenith"
     * @readonly
     * @type {string}
     */
    static unitZenith;
    /**
     * @default "warn"
     * @readonly
     * @type {string}
     */
    static warn;
    /**
     * @default "wave0"
     * @readonly
     * @type {string}
     */
    static wave0;
    /**
     * @default "wave1"
     * @readonly
     * @type {string}
     */
    static wave1;
    /**
     * @default "wave2"
     * @readonly
     * @type {string}
     */
    static wave2;
    /**
     * @default "wave3"
     * @readonly
     * @type {string}
     */
    static wave3;
}

//#endregion

//#region Classes

/**
 * A 2D Vector of floating point numbers.
 */
class Vec2 {
    /**
     * @param {number} x The x coordinate
     * @param {number} y The y coordinate
     */
    constructor(x, y) { }

    /**
     * Adds two vectors.
     * @param {Vec2} u The first vector.
     * @param {Vec2} v The second vector.
     * @returns {Vec2} The sum of the two vectors.
     */
    static add(u, v) { }

    /**
     * Subtracts the second vector from the first vector.
     * @param {Vec2} u The vector to subtract from.
     * @param {Vec2} v The vector to subtract.
     * @returns {Vec2} The difference of the two vectors.
     */
    static sub(u, v) { }

    /**
     * Negates a vector by negating both components.
     * @param {Vec2} v The vector to negate.
     * @returns {Vec2} The negated vector.
     */
    static neg(v) { }

    /**
     * Scales a vector by a scaling factor.
     * @param {Vec2} v The vector to scale.
     * @param {number} s The scaling factor.
     * @returns {Vec2} The scaled vector.
     */
    static scale(v, s) { }
}

/**
 * A color made up of red, green, blue and alpha.
 */
class Color {
    /**
     * @param {number} r The red component.
     * @param {number} g The green component.
     * @param {number} b The blue component.
     * @param {number} a The alpha component.
     */
    constructor(r, g, b, a) { }

    /**
     * Mixes two colors together according to its mode.
     * - mix: Interpolate between the colors.
     * - add: Add the two colors.
     * - sub: Subtract `col2` from `col1`.
     * - mul: Multiply the two colors.
     * - div: Divide `col1` by `col2`.
     * - and: Bitwise AND.
     * - or: Bitwise OR.
     * - xor: Bitwise XOR.
     * - not: Bitwise NOT on `col1`.
     * @param {Color} col1 The first color.
     * @param {Color} col2 The second color.
     * @param {number} amount The amount of the second color.
     * @param {string} [mode="mix"] The mixing mode.
     * @returns {Color} The mixed color.
     */
    static mix(col1, col2, amount, mode = "mix") { }
    /**
     * Parses a color from a string.
     * @param {string} str The string
     * @returns {Color} The parsed color
     */
    static parse(str) { }

    /**
     * `#00000066`
     * @readonly
     * @type {Color}
     */
    static shadow;
    /**
     * `#ffd37f`
     * @readonly
     * @type {Color}
     */
    static accent;
    /**
     * `#bfecf3`
     * @readonly
     * @type {Color}
     */
    static ui;
    /**
     * `#57639a`
     * @readonly
     * @type {Color}
     */
    static uiDark;
    /**
     * `#ff584c`
     * @readonly
     * @type {Color}
     */
    static hit;
    /**
     * `#84f490`
     * @readonly
     * @type {Color}
     */
    static heal;
    /**
     * `#00000000`
     * @readonly
     * @type {Color}
     */
    static clear;
    /**
     * `#ffffff`
     * @readonly
     * @type {Color}
     */
    static white;
    /**
     * `#000000`
     * @readonly
     * @type {Color}
     */
    static black;
    /**
     * `#7f7f7f`
     * @readonly
     * @type {Color}
     */
    static gray;
    /**
     * `#4169e1`
     * @readonly
     * @type {Color}
     */
    static royal;
    /**
     * `#ff7f50`
     * @readonly
     * @type {Color}
     */
    static coral;
    /**
     * `#ffa500`
     * @readonly
     * @type {Color}
     */
    static orange;
    /**
     * `#ff0000`
     * @readonly
     * @type {Color}
     */
    static red;
    /**
     * `#ff00ff`
     * @readonly
     * @type {Color}
     */
    static magenta;
    /**
     * `#a020f0`
     * @readonly
     * @type {Color}
     */
    static purple;
    /**
     * `#00ff00`
     * @readonly
     * @type {Color}
     */
    static green;
    /**
     * `#0000ff`
     * @readonly
     * @type {Color}
     */
    static blue;
    /**
     * `#ff69b4`
     * @readonly
     * @type {Color}
     */
    static pink;
    /**
     * `#ffff00`
     * @readonly
     * @type {Color}
     */
    static yellow;
}

/**
 * A custom entity.
 */
class CustomEntity {
    /**
     * The grid position of the entity.
     * @type {Vec2}
     * @default new Vec2(0)
     */
    pos;
    /**
     * The sprite of the entity.
     * @type {string}
     * @default ""
     */
    sprite;
    /**
     * The rotation of the entity in degrees.
     * @type {number}
     * @default 0
     */
    rot;
    /**
     * The scale of the entity.
     * @type {number}
     * @default 1
     */
    scl;
    /**
     * The real position of the entity.
     * @type {Vec2}
     * @readonly
     */
    smoothPos;
    /**
     * Whether the object is being deleted.
     * @type {bool}
     * @readonly
     */
    deleting;
    /**
     * Whether the object is being deleted immediately.
     * @readonly
     */
    deletingImmediate;
    /**
     * The script of the entity. It is probably possible, but not recommended, to change this value.
     * @type {function():void}
     */
    script;

    /**
     * Deletes the entity with an animation.
     * The entity's script will still run until the end of the animation.
     * Calling this multiple times has no effect.
     */
    destroy() { }

    /**
     * Deletes the entity immediately without an animation.
     * The entity's script will not run after this function is called.
     * Calling this multiple times has no effect.
     * The entity will be removed from the game in the next frame.
     */
    destroyImmediate() { }
}

//#endregion

//#region Objects

/**
 * The current state of the game.
 * @readonly
 * @property {number} secs - Smoothed position of the music track in seconds.
 * @property {number} lastSecs - Last "discrete" music track position, internally used.
 * @property {number} time - Smooth game time, may not necessarily match seconds. Visuals only!
 * @property {number} globalTime - The global time that is independent of the current beatmap. Very useful for animating values. Does not freeze in menus or when the game is paused (TODO actually test this).
 * @property {number} rawBeat - Raw beat calculated based on music position.
 * @property {number} moveBeat - Beat calculated as countdown after a music beat happens. Smoother, but less precise.
 * @property {Boolean} newTurn - If true, a new turn was just fired this frame
 * @property {number} hitTime - Snaps to 1 when player is hit for health animation.
 * @property {number} healTime - Snaps to 1 when player is healed. Seems like healing is an unimplemented mechanic in the base game.
 * @property {int} points - Points awarded based on various events.
 * @property {int} turn - Beats that have passed total.
 * @property {int} hits - The number of times the player has been hit this map. (?)
 * @property {int} totalHits - Same as state.hits, probably.
 * @property {int} misses - The number of times the player has missed an input this map. (?)
 * @property {number} currentBpm - The current BPM (beats per minute).
 * @property {Vec2} playerPos - Last known player position.
 * @property {number} beatSpacing - The time between two beats.
 */
var state = {
    /**
     * Smoothed position of the music track in seconds.
     * @type {number}
     * @readonly
     */
    secs,
    /**
     * Last "discrete" music track position, internally used.
     * @type {number}
     * @readonly
     */
    lastSecs,
    /**
     * Smooth game time, may not necessarily match seconds. Visuals only!
     * @type {number}
     * @readonly
     */
    time,
    /**
     * The global time that is independent of the current beatmap. Very useful for animating values. Does not freeze in menus or when the game is paused.
     * @type {number}
     * @readonly
     */
    globalTime,
    /**
     * Raw beat calculated based on music position.
     * @type {number}
     * @readonly
     */
    rawBeat,
    /**
     * Beat calculated as countdown after a music beat happens. Smoother, but less precise.
     * @type {number}
     * @readonly
     */
    moveBeat,
    /**
     * If true, a new turn was just fired this frame
     * @type {Boolean}
     * @readonly
     */
    newTurn,
    /**
     * Snaps to 1 when player is hit for health animation.
     * @type {number}
     * @readonly
     */
    hitTime,
    /**
     * Snaps to 1 when player is healed. Seems like healing is an unimplemented mechanic in the base game.
     * @type {number}
     * @readonly
     */
    healTime,
    /**
     * Points awarded based on various events.
     * @type {int}
     * @readonly
     */
    points,
    /**
     * Beats that have passed total.
     * @type {int}
     * @readonly
     */
    turn,
    /**
     * The number of times the player has been hit this map. (?)
     * @type {int}
     * @readonly
     */
    hits,
    /**
     * Same as state.hits, probably.
     * @type {int}
     * @readonly
     */
    totalHits,
    /**
     * The number of times the player has missed an input this map. (?)
     * @type {int}
     * @readonly
     */
    misses,
    /**
     * The current BPM (beats per minute).
     * @type {number}
     * @readonly
     */
    currentBpm,
    /**
     * Last known player position.
     * @type {Vec2}
     * @readonly
     */
    playerPos,
    /**
     * The time between two beats.
     * @type {number}
     * @readonly
     */
    beatSpacing,
    /**
     * The current interpolated beat.
     * @type {number}
     * @readonly
     */
    smoothTurn
}

//#endregion

//#region Value functions

/**
 * Converts pixels into world units.
 * @param {int} x The length in pixels.
 * @returns {number} The length in world units.
 */
function px(x) { }

/**
 * Used for displaying the unit splash when rolling / clicking on a unit in
 * the menu. Returns a scaling vector dependent on the size of the screen and
 * the time until the unit appears. Only usable in the context of unit splash
 * drawing.
 * @param {number} [base=0.175] The base scale of the unit splash.
 * @returns {Vec2} The scaling vector.
 */
function getScl(base = 0.175) { }

/**
 * Used for displaying the unit splash when rolling / clicking on a unit in the
 * menu. Returns a displacement vector that is used to slightly move the unit
 * up and down periodically. Only usable in the context of unit splash drawing.
 * @param {number} scl The amplitude of the hover effect.
 * @param {number} offset The vertical offset of the hover effect.
 */
function hoverOffset(scl = 0.65, offset = 0) { }

/**
 * Converts `x` from degrees to radians.
 * @param {number} x The value to convert.
 * @returns {number} The value in radians.
 */
function rad(x) { }

/**
 * Converts `x` from radians to degrees.
 * @param {number} x The value to convert.
 * @returns {number} The value in degrees.
 */
function deg(x) { }

//#endregion

//#region Pattern Drawing

/**
 * Draws a circular audio spectrum. Never used in the base game.
 * @param {Vec2} pos The position of the spectrum.
 * @param {number} [radius=px(90)] The inner radius of the spectrum.
 * @param {number} [length=8] The length of the spectrum bars.
 * @param {Color} [color=Color.white] The color of the spectrum.
 */
function drawFft(pos, radius = px(90), length = 8, color = Color.white) { }

/**
 * Draws the playing field with diagonal highlighted tiles that move with the beat. Should only be used inside levels.
 */
function drawTiles() { }

/**
 * Draws the playing field with an audio spectrum. Never used in the base game. Should only be used inside levels.
 */
function drawTilesFft() { }

/**
 * Draws the playing field with tiles highlighted in a repeating square pattern. Should only be used inside levels.
 * @param {Color} [col1=Color.white] The color of the normal tiles.
 * @param {Color} [col2=Color.blue] The color of the highlighted tiles.
 */
function drawTilesSquare(col1 = Color.white, col2 = Color.blue) { }

/**
 * Draws a single color background.
 * @param {Color} col The color of the background.
 */
function drawBackground(col = Color.white) { }

/**
 * Draws construction-tape-like stripes. If used inside a level, scrolls from right to left with the beat.
 * @param {Color} [col1=Color.pink] Background color.
 * @param {Color} [col2=Color.mix(Color.pink, Color.white, 0.2)] Stripe color.
 * @param {number} [angle=Math.rad(135)] The angle of the stripes.
 */
function drawStripes(col1 = Color.pink, col2 = Color.mix(Color.pink, Color.white, 0.2), angle = Math.rad(135)) { }

/**
 * Draws a square that flashes and changes size with the beat. Only works inside levels.
 * @param {Color} [col=Color.mix(Color.pink, Color.white, 0.7)] The color of the square.
 */
function drawBeatSquare(col = Color.mix(Color.pink, Color.white, 0.7)) { }

/**
 * Same as `DrawBeatSquare`, but flashes in a different pattern. Only works inside levels.
 * @param {Color} col The color of the square.
 */
function drawBeatAlt(col) { }


/**
 * Draws regular polygons in a circle around a position.
 * @param {Vec2} pos The position to draw the polygons around.
 * @param {Color} col The color of the polygons.
 * @param {number} len How far away the polygons are from the position.
 * @param {number} rad The size of the polygons.
 * @param {number} [offset=Math.rad(45)] Additional rotation around the target position applied to each polygon.
 * @param {int} [amount=4] The number of polygons to draw.
 * @param {int} [sides=3] How many sides each polygon has.
 * @param {number} [shapeOffset=Math.rad(0)] Additional rotation applied to each polygon around its own center.
 */
function drawTriSquare(pos, col, len, rad, offset = Math.rad(45), amount = 4, sides = 3, shapeOffset = Math.rad(0)) { }

/**
 * Draws stripes radially from the center. (TODO better explanation)
 * @param {Color} col1 The first color.
 * @param {Color} col2 The second color.
 * @param {int} [blades=10] The number of stripes to draw.
 */
function drawSpin(col1, col2, blades = 10) { }

/**
 * Draws a "fan" of triangles. (TODO better explanation)
 * @param {Vec2} pos The position to center the fan on.
 * @param {Color} col1 The inner color of the triangles.
 * @param {Color} col2 The outer color of the triangles.
 * @param {number} [len=5] The radius of the fan.
 * @param {int} [blades=10] The number of triangles that the fan is made of.
 * @param {int} [spacing=2] How often a triangle occurs.
 */
function drawSpinGradient(pos, col1, col2, len = 5, blades = 10, spacing = 2) { }

/**
 * Draws a central layered regular polygon surrounded by smaller "sattelite" polygons. Flashes and rotates with the beat. Only works inside levels.
 * @param {Color} col1 The normal color.
 * @param {Color} col2 The flash color.
 * @param {int} [sides=4] The number of sides of the central polygon.
 * @param {number} [rad=2.5] The radius of the central shape.
 * @param {number} [turnSpeed=Math.rad(19)] By how much the central shape rotates every beat.
 * @param {int} [rads=6] The number of sattelite shapes.
 * @param {int} [radsides=4] The number of sides of the sattelite polygons.
 * @param {number} [radOff=7] How far away the sattelite shapes orbit.
 * @param {number} [radrad=1.3] The radius of the sattelite shapes.
 * @param {number} [radrotscl=0.25] By how much the sattelite shapes will orbit relative to the central shape's rotation. The sattelites orbit in the opposite direction as the central shape spins.
 */
function drawSpinShape(col1, col2, sides = 4, rad = 2.5, turnSpeed = Math.rad(19), rads = 6, radsides = 4, radOff = 7, radrad = 1.3, radrotscl = 0.25) { }

/**
 * Draws concentric polygons of alternating colors around the center.
 * @param {Color} col1 The first color.
 * @param {Color} col2 The second color.
 * @param {int} [sides=4] How many sides the polygons have.
 * @param {number} [spacing=2.5] The distance between each polygon "ring".
 * @param {number} [angle=Math.rad(90)] The angle of the polygon.
 */
function drawShapeBack(col1, col2, sides = 4, spacing = 2.5, angle = Math.rad(90)) { }

/**
 * Draws repeating rotated squares that move towards the center with the beat. Only works inside levels.
 * @param {Color} col The color of the squares.
 */
function drawFadeShapes(col) { }

/**
 * Draws pinkish squares with trails that move down-left with the beat. Only works inside levels.
 * @param {int} [amount=80] The number of shapes to draw.
 */
function drawRain(amount = 80) { }

/**
 * Draws cherry petals that fall down-left. Only works inside levels.
 */
function drawPetals() { }

/**
 * Draws "skats". Used for the credits. Behaves strangely in levels.
 */
function drawSkats() { }

/**
 * Draws clouds in the upper half of the screen. Only works inside levels.
 * @param {Color} [col=Color.white] The color of the clouds.
 */
function drawClouds(col = Color.white) { }

/**
 * Draws clouds in the upper half of the screen. Only works inside levels.
 * @param {Color} [col=Color.white] The color of the clouds.
 */
function drawLongClouds(col = Color.white) { }

/**
 * Draws stars in different shapes and sizes that flash with the beat. Only works inside levels.
 * @param {Color} [col=Color.white] The normal color of the stars.
 * @param {Color} [flash=Color.white] The flash color of the stars.
 * @param {int} [amount=40] The number of stars to draw.
 * @param {int} [seed=1] The random seed.
 */
function drawStars(col = Color.white, flash = Color.white, amount = 40, seed = 1) { }

/**
 * Draws triangles that flash with the beat and move down-left. Only works inside levels.
 * @param {Color} [col1=Color.white] The normal color of the triangles.
 * @param {Color} [col2=Color.white] The flash color of the triangles.
 * @param {int} [amount=50] The number of triangles to draw.
 * @param {int} [seed=1] The random seed.
 */
function drawTris(col1 = Color.white, col2 = Color.white, amount = 50, seed = 1) { }

/**
 * Draws a lattice of squares with alternating sizes. The sizes of the squares swap with the beat. Only works inside levels.
 * @param {Color} [col=Color.white] The color of the squares.
 */
function drawBounceSquares(col = Color.white) { }

/**
 * Draws circles in random sizes that move around the screen in random directions. This effect is used for Mono, Oct and Sei.
 * @param {Color} [col=Color.white] The color of the circles.
 * @param {number} [time=state.time] The circles will move if you put in a value that changes over time.
 * @param {int} [amount=50] The number of circles to draw.
 * @param {int} [seed=1] The random seed.
 * @param {number} [minSize=2] The smallest size a circle can be.
 * @param {number} [maxSize=7] The largest size a circle can be.
 * @param {number} [moveSpeed=0.2] The speed at which the circles move.
 */
function drawCircles(col = Color.white, time = state.time, amount = 50, seed = 1, minSize = 2, maxSize = 7, moveSpeed = 0.2) { }

/**
 * Draws triangles in random sizes that point away from the center and move around the screen in random directions. This effect is used for Crawler.
 * @param {Color} [col=Color.white] The color of the triangles.
 * @param {number} [time=state.time] The triangles will move if you put in a value that changes over time.
 * @param {int} [amount=50] The number of triangles to draw
 * @param {int} [seed=1] The random seed.
 */
function drawRadTris(col = Color.white, time = state.time, amount = 50, seed = 1) { }

/**
 * Draws moving circles with a trail of smaller circles ("missiles"). This effect is used for Zenith.
 * @param {Color} [col=Color.white] The color of the circles.
 * @param {number} [time=state.time] The circles will move if you put in a value that changes over time.
 * @param {int} [amount=50] The number of circles to draw (not including the trailing circles).
 * @param {int} [seed=1] The random seed.
 */
function drawMissiles(col = Color.white, time = state.time, amount = 50, seed = 1) { }

/**
 * Draws squares that fall down while spinning and changing color. This effect is used for Quad.
 * @param {Color} [col1=Color.white] The initial color of the squares.
 * @param {Color} [col2=Color.white] The color the squares change to over their lifetime.
 * @param {number} [time=state.time] The squares will move if you put in a value that changes over time.
 * @param {int} [amount=50] The number of squares to draw.
 */
function drawFallSquares(col1 = Color.white, col2 = Color.white, time = state.time, amount = 50) { }

/**
 * Draws circles that move upwards while becoming smaller and changing color. This effect is used for Oxynoe.
 * @param {Color} [col1=Color.white] The initial color of the circles.
 * @param {Color} [col2=Color.white] The color the circles change to.
 * @param {number} [time=state.time] The circles will move if you put in a value that changes over time.
 * @param {int} [amount=80] The number of circles to draw.
 */
function drawFlame(col1 = Color.white, col2 = Color.white, time = state.time, amount = 80) { }

/**
 * Draws squares that slowly move around the screen and periodically shrink and grow. This effect is used for Alpha.
 * @param {Color} [col=Color.white] The color of the squares.
 * @param {number} [time=state.time] The squares will move if you put in a value that changes over time.
 * @param {int} [amount=50] The number of squares to draw.
 * @param {int} [seed=2] The random seed.
 */
function drawSquares(col = Color.white, time = state.time, amount = 50, seed = 2) { }

/**
 * Draws a line with rounded endpoints.
 * @param {Vec2} pos The position of the midpoint of the line.
 * @param {number} angle The angle of the line.
 * @param {number} len The length of the line.
 * @param {Color} [color=Color.white] The color of the line.
 * @param {number} [stroke=1] The thickness of the line.
 */
function drawRoundLine(pos, angle, len, color = Color.white, stroke = 1) { }

/**
 * Draws rounded lines that move around slightly (looks a bit like rays of light).
 * @param {Color} [col=Color.white] The color of the lines.
 * @param {int} [seed=1] The random seed.
 * @param {int} [amount=30] The number of lines to draw.
 * @param {number} [angle=Math.rad(45)] The angle at which to draw the lines.
 */
function drawLines(col = Color.white, seed = 1, amount = 30, angle = Math.rad(45)) { }

/**
 * Draws rounded lines pointing at the center of the screen that move around slightly.
 * @param {Color} [col=Color.white] The color of the lines.
 * @param {int} [seed=6] The random seed.
 * @param {int} [amount=40] The number of lines to draw.
 * @param {number} [stroke=0.25] The thickness of the lines.
 * @param {number} [posScl=1] How far away the lines are from the center on average. A higher value means the lines are further away.
 * @param {number} [lenScl=1] How long the lines are.
 */
function drawRadLinesRound(col = Color.white, seed = 6, amount = 40, stroke = 0.25, posScl = 1, lenScl = 1) { }

/**
 * Draws circles in random sizes scattered around the center of the screen.
 * @param {Color} [col=Color.white] The color of the circles.
 * @param {int} [seed=7] The random seed.
 * @param {int} [amount=40] The number of circles to draw.
 * @param {number} [fin=0.5] How far away the circles are from the center on average. Also scales the circles.
 */
function drawRadCircles(col = Color.white, seed = 7, amount = 40, fin = 0.5) { }

/**
 * Draws rounded lines pointing to a position. The angle between all lines is the same.
 * @param {Vec2} pos The position the lines will point to.
 * @param {Color} col The color of the lines.
 * @param {int} [amount=10] The number of lines to draw.
 * @param {number} [offset=8] How far away the midpoint of each line is from the targeted position.
 * @param {number} [len=3] The length of the line.
 * @param {number} [angleOffset=0] Additional rotation around the target position applied to each line.
 */
function drawSpikes(pos, col = Color.white, amount = 10, offset = 8, len = 3, angleOffset = 0) { }

/**
 * Draws a gradient across the screen.
 * @param {Color} [col1=Color.clear] The color of the bottom left corner.
 * @param {Color} [col2=Color.clear] The color of the bottom right corner.
 * @param {Color} [col3=Color.clear] The color of the top right corner.
 * @param {Color} [col4=Color.clear] The color of the top left corner.
 */
function drawGradient(col1 = Color.clear, col2 = Color.clear, col3 = Color.clear, col4 = Color.clear) { }

/**
 * Draws a vertical gradient.
 * @param {Color} [col1=Color.clear] The bottom color.
 * @param {Color} [col2=Color.clear] The top color.
 */
function drawVertGradient(col1 = Color.clear, col2 = Color.clear) { }

/**
 * Draws concentric polygons around the center of the screen that increase in thickness further out.
 * @param {Color} [col=Color.white] The color of the polygons.
 * @param {number} [offset=0] The offset of the first polygon from the center. Periodic. (TODO explain that better)
 * @param {int} [amount=10] The number of polygons to draw.
 * @param {int} [sides=4] The number of sides the polygon will have.
 */
function drawZoom(col = Color.white, offset = 0, amount = 10, sides = 4) { }

/**
 * The screen becomes light blue from the top left corner. This effect is used to transition between the menu and levels.
 * @param {number} time The effect will move if you put in a value that changes over time.
 */
function drawFadeOut(time) { }

/**
 * A light blue screen disappears into the bottom right corner. This effect is used to transition between the menu and levels.
 * @param {number} time The effect will move if you put in a value that changes over time. The value should change in reverse (?).
 */
function drawFadeIn(time) { }

/**
 * Draws many stripes pointing towards the center. Only works inside levels.
 * @param {Color} col The color of the stripes.
 * @param {number} [time=state.secs] The stripes will move if you put in a value that changes over time.
 */
function drawSpace(col, time) { }

/**
 * Draws the current unit's splash image. Should only be used in unit splash drawing.
 * @param {Vec2} pos Where to draw the unit.
 * @param {Vec2} [scl=vec2(1, 1)] Scale of the unit. 
 * @param {Color} [color=Color.white] Color of the unit.
 * @param {string} [part=""] Suffix of the texture file to draw (e.g. *"-glow"* to draw *"mono-glow.png"*).
 */
function drawUnit(pos, scl = new Vec2(1, 1), color = Color.white, part = "") { }

//#endregion

//#region Basic Drawing

/**
 * Draws a filled quad with a gradient.
 * @param {Vec2} v1 A vertex of the quad.
 * @param {Vec2} v2 A vertex of the quad.
 * @param {Vec2} v3 A vertex of the quad.
 * @param {Vec2} v4 A vertex of the quad.
 * @param {Color} c1 The color of the quad at *v1*.
 * @param {Color} c2 The color of the quad at *v2*.
 * @param {Color} c3 The color of the quad at *v3*.
 * @param {Color} c4 The color of the quad at *v4*.
 * @param {number} [z=0] The z layer of the quad.
 */
function drawFillQuadGradient(v1, v2, v3, v4, c1, c2, c3, c4, z = 0) { }

/**
 * Draws a filled quad with a single color.
 * @param {Vec2} v1 A vertex of the quad.
 * @param {Vec2} v2 A vertex of the quad.
 * @param {Vec2} v3 A vertex of the quad.
 * @param {Vec2} v4 A vertex of the quad.
 * @param {Color} color The color of the quad.
 * @param {number} [z=0] The z layer of the quad.
 */
function drawFillQuad(v1, v2, v3, v4, color, z = 0) { }

/**
 * Draws a filled rectangle.
 * @param {number} x The x coordinate of the bottom left corner.
 * @param {number} y The y coordinate of the bottom left corner.
 * @param {number} w The width of the rectangle.
 * @param {number} h The height of the rectangle.
 * @param {Color} [color=Color.white] The color of the rectangle.
 * @param {number} [z=0] The z layer of the rectangle.
 */
function drawFillRect(x, y, w, h, color = Color.white, z = 0) { }

/**
 * @param {Vec2} pos The position of the midpoint of the square.
 * @param {number} radius The radius of the square (half the side length).
 * @param {Color} [color=Color.white] The color of the square.
 * @param {number} [z=0] The z layer of the square.
 */
function drawFillSquare(pos, radius, color = Color.white, z = 0) { }

/**
 * Draws a filled triangle with a single color.
 * @param {Vec2} v1 A vertex of the triangle.
 * @param {Vec2} v2 A vertex of the triangle.
 * @param {Vec2} v3 A vertex of the triangle.
 * @param {Color} color The color of the triangle.
 * @param {number} [z=0] The z layer of the triangle.
 */
function drawFillTri(v1, v2, v3, color, z = 0) { }

/**
 * Draws a filled triangle with a gradient.
 * @param {Vec2} v1 A vertex of the triangle.
 * @param {Vec2} v2 A vertex of the triangle.
 * @param {Vec2} v3 A vertex of the triangle.
 * @param {Color} c1 The color of the triangle at *v1*.
 * @param {Color} c2 The color of the triangle at *v2*.
 * @param {Color} c3 The color of the triangle at *v3*.
 * @param {number} [z=0] The z layer of the triangle.
 */
function drawFillTriGradient(v1, v2, v3, c1, c2, c3, z = 0) { }

/**
 * Draws a filled circle.
 * @param {Vec2} pos The position of the midpoint of the circle.
 * @param {number} rad The radius of the circle.
 * @param {Color} [color=Color.white] The color of the circle.
 * @param {number} [z=0] The z layer of the circle.
 */
function drawFillCircle(pos, rad, color = Color.white, z = 0) { }

/**
 * Draws a filled polygon.
 * @param {Vec2} pos The position of the center of the polygon.
 * @param {int} sides The number of sides the polygon has.
 * @param {number} radius The radius of the polygon.
 * @param {number} [rotation=0] The rotation of the polygon.
 * @param {Color} [color=Color.white] The color of the polygon.
 * @param {number} [z=0] The z layer of the polygon.
 */
function drawFillPoly(pos, sides, radius, rotation = 0, color = Color.white, z = 0) { }

/**
 * Draws a regular polygon with a gradient to the middle.
 * @param {Vec2} pos The position of the shape.
 * @param {number} radius The radius of the shape.
 * @param {int} [sides=20] The number of sides the polygon has. With the default value of 20, it looks close to a circle.
 * @param {Color} [centerColor=Color.white] The color of the shape at the center.
 * @param {Color} [edgeColor=Color.white] The color of the shape at the edge.
 * @param {number} [z=0] The z layer of the shape.
 */
function drawFillLight(pos, radius, sides, centerColor = Color.white, edgeColor = Color.white, z = 0) { }

/**
 * Draws a line between two points.
 * @param {Vec2} p1 The position of the start point.
 * @param {Vec2} p2 The position of the end point.
 * @param {number} [stroke=px(1)] The thickness of the line.
 * @param {Color} [color=Color.white] The color of the line.
 * @param {bool} [square=true] ???
 * @param {number} [z=0] The z layer of the line.
 */
function drawLine(p1, p2, stroke = px(1), color = Color.white, square = true, z = 0) { }

/**
 * Draws a line from a point at an angle.
 * @param {Vec2} p The position of the start point.
 * @param {number} angle The angle of the line.
 * @param {number} len The length of the line.
 * @param {number} [stroke=px(1)] The thickness of the line.
 * @param {Color} [color=Color.white] The color of the line.
 * @param {bool} [square=true] ???
 * @param {number} [z=0] The z layer of the line.
 */
function drawLineAngle(p, angle, len, stroke = px(1), color = Color.white, square = true, z = 0) { }

/**
 * @param {Vec2} p The position of the midpoint.
 * @param {number} angle The angle of the line.
 * @param {number} len The length of the line.
 * @param {number} [stroke=px(1)] The thickness of the line.
 * @param {Color} [color=Color.white] The color of the line.
 * @param {bool} [square=true] ???
 * @param {number} [z=0] The z layer of the line.
 */
function drawLineAngleCenter(p, angle, len, stroke = px(1), color = Color.white, square = true, z = 0) { }

/**
 * Draws a rectangle outline.
 * @param {Vec2} pos The position of the bottom left corner of the rectangle.
 * @param {Vec2} size The size of the rectangle as a vector of *(width, height)*.
 * @param {number} [stroke=px(1)] The thickness of the outline.
 * @param {Color} [color=Color.white] The color of the outline.
 * @param {number} [z=0] The z layer of the rectangle.
 * @param {number} [margin=0] Seems to make the rectangle smaller.
 */
function drawLineRect(pos, size, stroke = px(1), color = Color.white, z = 0, margin = 0) { }

/**
 * Draws a square outline.
 * @param {Vec2} pos The position of the midpoint.
 * @param {number} rad The radius of the square.
 * @param {number} [stroke=px(1)] The thickness of the outline.
 * @param {Color} [color=Color.white] The color of the outline.
 * @param {number} [z=0] The z layer of the square.
 */
function drawLineSquare(pos, rad, stroke = px(1), color = Color.white, z = 0) { }

/**
 * Draws lines pointing at a target position.
 * @param {Vec2} pos The target position.
 * @param {int} sides The number of lines to draw.
 * @param {number} radius The distance from the target point to the start points of the lines.
 * @param {number} len The length of the lines.
 * @param {number} [stroke=px(1)] The thickness of the outline.
 * @param {number} [rotation=0]
 * @param {Color} [color=Color.white] The color of the lines.
 * @param {number} [z=0] The z layer of the lines.
 */
function drawRadLines(pos, sides, radius, len, stroke = px(1), rotation = 0, color = Color.white, z = 0) { }

/**
 * Draws a regular polygon outline.
 * @param {Vec2} pos The position of the center of the polygon.
 * @param {int} sides The number of sides the polygon has.
 * @param {number} radius The radius of the polygon.
 * @param {number} [rotation=0] The rotation of the polygon.
 * @param {number} [stroke=px(1)] The line thickness of the polygon.
 * @param {Color} [color=Color.white] The color of the polygon.
 * @param {number} [z=0] The z layer of the polygon.
 */
function drawPoly(pos, sides, radius, rotation = 0, stroke = px(1), color = Color.white, z = 0) { }

/**
 * Draws a polygonal ring sector.
 * @param {Vec2} pos The midpoint of the ring.
 * @param {int} sides The number of sides of the ring sector.
 * @param {number} angleFrom The angle where the sector starts.
 * @param {number} angleTo The angle where the sector ends.
 * @param {number} radiusFrom The inner radius of the ring.
 * @param {number} radiusTo The outer radius of the ring.
 * @param {number} [rotation=0] The rotation of the sector.
 * @param {Color} [color=Color.white] The color of the ring.
 * @param {number} [z=0] The z layer of the ring.
 */
function drawArcRadius(pos, sides, angleFrom, angleTo, radiusFrom, radiusTo, rotation = 0, color = Color.white, z = 0) { }

/**
 * Draws a polygonal arc.
 * @param {Vec2} pos The position of the arc.
 * @param {int} sides The number of sides of the arc.
 * @param {number} angleFrom The angle where the arc starts.
 * @param {number} angleTo The angle where the arc ends.
 * @param {number} radius The radius of the arc.
 * @param {number} [rotation=0] The rotation of the arc.
 * @param {number} [stroke=px(1)] The thickness of the outline.
 * @param {Color} [color=Color.white] The color of the outline.
 * @param {number} [z=0] The z layer of the polygon.
 */
function drawArc(pos, sides, angleFrom, angleTo, radius, rotation = 0, stroke = px(1), color = Color.white, z = 0) { }

/**
 * Draws a polygonal crescent shape.
 * @param {Vec2} pos The midpoint of the shape.
 * @param {int} sides The number of sides of the shape.
 * @param {number} angleFrom The angle where the crescent starts.
 * @param {number} angleTo The angle where the crescent ends.
 * @param {number} radius The radius of the shape.
 * @param {number} [rotation=0] The rotation of the shape.
 * @param {number} [stroke=px(1)] The width of the thickest part of the crescent.
 * @param {Color} [color=Color.white] The color of the outline.
 * @param {number} [z=0] The z layer of the shape.
 */
function drawCrescent(pos, sides, angleFrom, angleTo, radius, rotation = 0, stroke = px(1), color = Color.white, z = 0) { }

/**
 * Draws a polygon outline.
 * @param {Array} points An array of points to connect into a shape.
 * @param {bool} [wrap=false] Whether the last point should connect to the first point.
 * @param {number} [stroke=px(1)] The width of the outline.
 * @param {Color} [color=Color.white] The color of the shape.
 * @param {number} [z=0] The z layer of the shape.
 */
function drawShape(points, wrap = false, stroke = px(1), color = Color.white, z = 0) { }

/**
 * Patterns will be drawn with bloom enabled until `endBloom()` is called. Only works in unit splash drawing.
 */
function beginBloom() { }



/**
 * Disables bloom for pattern drawing. Only works in unit splash drawing.
 */
function endBloom() { }

//#endregion

//#region Ability

/**
 * Creates a wall that blocks bullets and conveyors.
 * @param {Vec2} pos The tile where the wall will appear.
 * @param {string} [sprite="wall"] The sprite to use for the wall.
 * @param {int} [life=10] The time in turns until the wall disappears.
 * @param {int} [health=3] How many bullets the wall can block before it is destroyed.
 */
function makeWall(pos, sprite = "wall", life = 10, health = 3) { }

/**
 * Damages (usually destroys) bullets, conveyors, etc. on a target tile.
 * @param {Vec2} target The tile to target.
 */
function damageBlocks(pos) { }

//#endregion

//#region Makers

/**
 * Callback for makeDelay.
 * 
 * @callback makeDelayCallback
 */

/**
 * Delays an action by a number of turns. Appears to be slightly bugged. Should only be used in map update scripts.
 * @param {int} delay The number of turns until the callback is executed minus one.
 * @param {makeDelayCallback} callback The function to execute after the delay.
 */
function makeDelay(delay, callback) { }

/**
 * Creates a bullet on the playing field. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the bullet.
 * @param {Vec2} dir The distance the bullet moves per turn. The bullet *can* move multiple squares in a direction at once (e.g. with *vec2(1, -2)*).
 * @param {string} [tex="bullet"] The texture of the bullet. (TODO list of values)
 */
function makeBullet(pos, dir, tex = "bullet") { }

/**
 * Creates a bullet on the playing field that disappears after a set amount of turns. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the bullet.
 * @param {Vec2} dir The distance the bullet moves per turn.
 * @param {string} [tex="bullet"] The texture of the bullet.
 * @param {int} [life=3] The number of turns after which the bullet disappears.
 */
function makeTimedBullet(pos, dir, tex = "bullet", life = 3) { }

/**
 * Creates a conveyor on the playing field. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the conveyor.
 * @param {Vec2} dir The distance the conveyor moves per turn.
 * @param {int} [length=2] The number of conveyor belts in a row. Only 1 and 2 work.
 * @param {string} [tex="conveyor"] The texture of the conveyor. Does not work with a length of 2.
 * @param {int} [gen=0] Unknown.
 */
function makeConveyor(pos, dir, length = 2, tex = "conveyor", gen = 0) { }

/**
 * Makes a one tile long laser segment. You should probably use `MakeLaser` instead. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the laser segment.
 * @param {Vec2} dir The direction in which the laser points.
 */
function makeLaserSegment(pos, dir) { }


/**
 * Creates a router that shoots conveyors. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the router.
 * @param {int} [length=2] The number of conveyors the router creates. Only 1 and 2 work.
 * @param {int} [life=2] The number of turns until the router disappears.
 * @param {bool} [diag=false] Whether the conveyors are shot diagonally.
 * @param {string} [tex="router"] The texture of the router.
 * @param {bool} [allDir=false] Whether the conveyors are in all eight directions.
 */
function makeRouter(pos, length = 2, life = 2, diag = false, tex = "router", allDir = false) { }

/**
 * Creates a sorter on the playing field that shoots conveyors and moves. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the sorter.
 * @param {Vec2} mdir The movement direction of the sorter.
 * @param {int} [moveSpace=2] The number of turns it takes for the sorter to move one tile.
 * @param {int} [spawnSpace=2] The delay between conveyor spawns.
 * @param {int} [length=1] The number of conveyors spawned. Only 1 and 2 work.
 */
function makeSorter(pos, mdir, moveSpace = 2, spawnSpace = 2, length = 1) { }

/**
 * Creates a turret on the playing field that moves and shoots bullets at the player. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the turret.
 * @param {Vec2} face The direction the turret is facing. Also the movement vector of the bullets spawned by the turret.
 * @param {int} [reload=4] The number of turns it takes to reload times two. (TODO check source)
 * @param {int} [life=8] The number of turns until the turret disappears.
 * @param {string} [tex="duo"] The texture of the turret.
 */
function makeTurret(pos, face, reload = 4, life = 8, tex = "duo") { }

/**
 * Creates an Arc turret on the playing field that moves across the screen, bounces from walls and leaves a trail of stationary bullets. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the Arc.
 * @param {Vec2} dir The movement vector of the Arc.
 * @param {string} [tex="arc"] The texture of the Arc.
 * @param {int} [bounces=1] The maximum number of times the Arc can bounce off of the wall.
 * @param {int} [life=3] The number of turns until the trail of bullets disappears.
 */
function makeArc(pos, dir, tex = "arc", bounces = 1, life = 3) { }

/**
 * Creates a bullet delayed by one turn.
 * @param {Vec2} pos The position of the bullet.
 * @param {Vec2} dir The distance the bullet moves per turn. 
 * @param {string} [tex=""] The texture of the bullet.
 */
function makeDelayBullet(pos, dir, tex = "") { }

/**
 * Creates a bullet delayed by one turn with an indicator at the position the bullet will appear.
 * @param {Vec2} pos The position of the bullet.
 * @param {Vec2} dir The distance the bullet moves per turn.
 * @param {string} [tex=""] The texture of the bullet.
 */
function makeDelayBulletWarn(pos, dir, tex = "") { }

/**
 * Shoots 8 bullets from a position in all 8 directions.
 * @param {Vec2} pos The position to shoot the bullets from.
 * @param {string} [tex=""] The texture of the bullets.
 */
function makeBulletCircle(pos, tex = "") { }

/**
 * Creates a Lancer turret on the playing field that shoots a laser across the playing field two turns later.
 * @param {Vec2} pos The position where the turret appears.
 * @param {Vec2} dir The direction the turret is pointing in. Only cardinal directions with a magnitude of one work (no diagonal lasers).
 */
function makeLaser(pos, dir) { }

/**
 * Creates a custom entity on the playing field. Should only be used in map update scripts.
 * @param {Vec2} pos The position of the entity.
 * @param {function():void} script The function to run each frame. `this` can be used in the function to access the entity (type is `CustomEntity`).
 * @param {int} [lifetime=-1] The number of turns the entity will exist. -1 for infinite.
 * @param {bool} [destructible=false] Whether the entity can be destroyed by the player.
 * @param {bool} [damagePlayer=false] Whether the entity damages the player on contact.
 * @param {bool} [deleteOnContact=false] Whether the entity is destroyed on contact with the player. Only works if `damagePlayer` is `true`.
 * @returns {CustomEntity} The created entity.
 */
function makeCustomEntity(pos, script, lifetime = -1, destructible = false, damagePlayer = false, deleteOnContact = false) { }

//#endregion

//#region Effects

/**
 * Creates an explosion effect on a tile.
 * @param {Vec2} pos The position of the tile where the effect will appear.
 */
function effectExplode(pos) { }

/**
 * Creates a green explosion effect on a tile.
 * @param {Vec2} pos The position of the tile where the effect will appear.
 */
function effectExplodeHeal(pos) { }

/**
 * Creates a warning effect (white square) on a tile.
 * @param {Vec2} pos The position of the tile where the effect will appear.
 * @param {number} life The lifetime of the effect. Usually a constant multiplied with *beatSpacing*.
 */
function effectWarn(pos, life) { }

/**
 * Creates a warning effect (white bullet) on a tile.
 * @param {Vec2} pos The position of the tile where the effect will appear.
 * @param {number} life The lifetime of the effect. Usually a constant multiplied with *beatSpacing*.
 * @param {number} rotation The rotation of the effect.
 */
function effectWarnBullet(pos, life, rotation) { }

/**
 * Creates a warning effect (large square) around a tile.
 * @param {Vec2} pos The position of the tile where the effect will appear.
 * @param {number} life The lifetime of the effect. Usually a constant multiplied with *beatSpacing*.
 * @param {number} [rotation=0] The size of the effect. Don't ask.
 */
function effectStrikeWave(pos, life, rotation) { }

//#endregion

//#region Other

/**
 * Changes the BPM of the current map.
 * @param {number} bpm The new BPM the map should have.
 */
function changeBpm(bpm) { }

/**
 * Writes a string to the console.
 * @param {string} message The message to log.
 */
function log(message) { }

/**
 * Imports a sprite from another mod so that it can be used in the current mod.
 * @param {string} name The name of the sprite in the source mod.
 * @param {string} namespace The namepace of the mod the sprite is from.
 * @param {string} [alias=name] The name the sprite will have in the current mod.
 */
function importSprite(name, namespace, alias = name) { }

//#endregion
