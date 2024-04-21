// Functions and classes in this file are only for highlighting purposes.
// This file is not executed by the mod loader.

class Color {
    /**
     * @param {number} r The red component
     * @param {number} g The green component
     * @param {number} b The blue component
     * @param {number} a The alpha component
     */
    constructor(r, g, b, a) { }
    /**
     * Mixes two colors together.
     * @param {Color} col1 The first color
     * @param {Color} col2 The second color
     * @param {number} amount The amount of the second color
     * @param {string} [mode="mix"] The mixing mode.
     * - mix: Interpolate between the colors.
     * - add: Add the two colors.
     * - sub: Subtract `col2` from `col1`.
     * - mul: Multiply the two colors.
     * - div: Divide `col1` by `col2`.
     * - and: Bitwise AND.
     * - or: Bitwise OR.
     * - xor: Bitwise XOR.
     * - not: Bitwise NOT on `col1`.
     * @returns {Color} The mixed color
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
    static acc
    /**
     * `#bfecf3`
     * @readonly
     * @type {Color}
     */ent;
    static ui;
    /**
     * `#57639a`
     * @readonly
     * @type {Color}
     */
    static uiDa
    /**
     * `#ff584c`
     * @readonly
     * @type {Color}
     */rk;
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
    static black
    /**
     * `#7f7f7f`
     * @readonly
     * @type {Color}
     */;
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
    static oran
    /**
     * `#ff0000`
     * @readonly
     * @type {Color}
     */ge;
    static red;
    /**
     * `#ff00ff`
     * @readonly
     * @type {Color}
     */
    static magenta
    /**
     * `#a020f0`
     * @readonly
     * @type {Color}
     */;
    static purple
    /**
     * `#00ff00`
     * @readonly
     * @type {Color}
     */;
    static green
    /**
     * `#0000ff`
     * @readonly
     * @type {Color}
     */;
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
 * Draws stripes on the screen.
 * @param {Color} [col1=colorPink] The first color
 * @param {Color} [col2=Color.mix(colorPink, colorWhite, 0.2)] The second color
 * @param {number} [angle=rad(135)] The angle of the stripes
 */
function drawStripes(col1 = colorPink, col2 = Color.mix(colorPink, colorWhite, 0.2), angle = rad(135)) { }