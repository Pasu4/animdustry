![](assets-raw/icon.png)

# Animdustry Mod Loader

A modloader for the anime gacha bullet hell rhythm game by Anuke.

[Downloads for windows/linux/android are available on the releases page.](https://github.com/Pasu4/animdustry/releases)

# Compiling

For information on compiling, please refer to [the original repository](https://github.com/Anuken/animdustry/blob/master/README.md#compiling).

# Credits

Original game by Anuke

Modloader programming and documentation by Pasu4

music used:

- [Aritus - For You](https://soundcloud.com/aritusmusic/4you)
- [PYC - Stoplight](https://soundcloud.com/pycmusic/stoplight)
- [Keptor's Room - Bright 79](https://soundcloud.com/topazeclub/bright-79)
- [Aritus - Pina Colada II](https://soundcloud.com/aritusmusic/pina-colada-ii-final)
- [ADRIANWAVE - Peach Beach](https://soundcloud.com/adrianwave/peach-beach)

# Documentation

## Folder structure

A mod is a folder containing files. This folder must be placed in the mods folder of the modloader. The location of this folder depends on your operation system:

- Windows: `%APPDATA%\animdustry\mods`
- Linux: `~/.config/animdustry/mods`

If the folder does not exist, you can create it, otherwise it will be created automatically on first startup of the modloader.

The folder structure of a mod is as follows:

```
modfolder
├── mod.json
├── credits.txt
├── maps
│   └── exampleMap.json
├── unitSplashes
│   └── exampleUnit.png
├── units
│   └── exampleUnit.json
└── unitSprites
    ├── exampleUnit-angery.png
    ├── exampleUnit-hit.png
    └── exampleUnit.png
```

- **mod.json:** Contains information about the mod.
- **credits.txt:** Additional credits added to the credits of the game. Credits will be auto-generated if this file is missing.
- **maps:** Contains the playable maps this mod adds (Not yet implemented).
- **unitSplashes:** Contains the unit splashes. Unit splashes must be named like the unit they belong to.
- **units**: Contains unit scripts. The name of a file should match the name of the unit.
- **unitSprites**: Contains in-game sprites for the units.

An example of a mod can be found [here](https://github.com/Pasu4/animdustry-mod-template).

## mod.json

A `mod.json` file must be be placed in the root folder of the mod. It is what tells the modloader that this folder contains a mod. The content of the file is as follows:

```json
{
    "name": "The name of your mod",
    "author": "You",
    "description": "Description of your mod"
}
```

## Custom Maps

Coming soon.

## Custom Units

Unit scripts describe how a unit is drawn and how it interacts with the game. To define a unit, first place a JSON file with the same name as your unit in the `units` folder. Its contents should look like this:

```json
{
    "name": "exampleUnit",
    "title": "-EXAMPLE-",
    "subtitle": "lorem ipsum",
    "abilityDesc": "dolor sit amet",
    "abilityReload": 4,
    "unmoving": false,
    "draw": [
        {"type": "SetVec2", "name": "pos", "value": "basePos - vec2(0, 0.5) + _hoverOffset * 0.5"},
        {"type": "DrawUnit", "pos": "pos - shadowOffset", "scl": "getScl(0.165)", "color": "shadowColor"},
        {"type": "DrawUnit", "pos": "pos", "scl": "getScl(0.165)"}
    ],
    "abilityProc": [

    ]
}
```

- **name:** The internal name of the unit. Used for loading files. Should be unique.
- **title:** The title of the unit displayed at the top of the screen when it is rolled or clicked in the menu.
- **subtitle:** The subtitle, displayed below the title in smaller letters. Usually used for a short description of the unit.
- **abilityDesc:** A description of the unit's ability, displayed in the bottom right corner. May also be used for other descriptions.
- **abilityReload:** How many turns it takes for the unit's ability to activate.
- **unmoving:** If the unit can move. Only used by Boulder in the base game. May be omitted.
- **draw:** An array of draw calls to execute each time the unit splash is drawn. More about draw calls in the chapter [API Calls](#api-calls).
- **abilityProc:** An array of function calls to execute when the unit's ability is activated. Not implemented yet.

To add a splash image to your unit, place an image file with the same name as your unit into the `unitSplashes` folder. To add in-game sprites of your unit, place the files `example.png` and `example-hit.png` in the `unitSprites` folder (replace "example" with the name of your unit). Those two files must exist for the unit to display properly. Additionally, an `example-angery.png` (not a typo) and `example-happy.png` file can be placed in the folder as well. The `-angery` sprite is displayed when the player misses a beat, and the `-happy` sprite is displayed one second before a level ends.

## Functions

Functions can be used inside math formulas.

- **float** *px(val)*: Converts pixel units into world units.
- **Vec2** *getScl(base)*: Used for displaying the unit splash when rolling / clicking on a unit in the menu. Returns a scaling vector dependent on the size of the screen and the time until the unit appears. Only usable in the context of unit splash drawing.
- **Vec2** *hoverOffset(scl, offset = 0)*: Used for displaying the unit splash when rolling / clicking on a unit in the menu. Returns a displacement vector that is used to slightly move the unit up and down periodically. Only usable in the context of unit splash drawing.
- **Vec2** *vec2(x, y)*: Constructs a 2D vector from x and y components.

## Variables

Variables beginning with "state_" are only available inside levels.

- **float** *state_secs*: Smoothed position of the music track in seconds.
- **float** *state_lastSecs*: Last "discrete" music track position, internally used.
- **float** *state_time*: Smooth game time, may not necessarily match seconds. Visuals only!
- **float** *state_rawBeat*: Raw beat calculated based on music position.
- **float** *state_moveBeat*: Beat calculated as countdown after a music beat happens. Smoother, but less precise.
- **float** *state_hitTime*: Snaps to 1 when player is hit for health animation.
- **float** *state_healTime*: Snaps to 1 when player is healed. Seems like healing is an unimplemented echaninc in the base game.
- **int** *state_points*: Points awarded based on various events.
- **int** *state_turn*: Beats that have passed total.
- **int** *state_hits*: The number of times the player has been hit this map. (?)
- **int** *state_totalHits*: Same as *state_hits*, probably.
- **int** *state_misses*: The number of times the player has missed an input this map. (?)

- **float** *fau_time*: The global time that is independent of the current beatmap. Very useful for animating values. Does not freeze in menus or when the game is paused (TODO actually test this).

- **Vec2** *basePos*: The base position of the unit splash. Only usable in the context of unit splash drawing.
- **Vec2** *_getScl*: Calls *getScl(0.175)* (default value). Only usable in the context of unit splash drawing.
- **Vec2** *_hoverOffset*: Calls *hoverOffset(0.65, 0)* (default value). Only usable in the context of unit splash drawing.
- **Vec2** *playerPos*: Last known player position.

- **Color** *shadowColor*: #00000066
- **Color** *colorAccent*: #ffd37f
- **Color** *colorUi*: #bfecf3
- **Color** *colorUiDark*: #57639a
- **Color** *colorHit*: #ff584c
- **Color** *colorHeal*: #84f490
- **Color** *colorClear*: #00000000
- **Color** *colorWhite*: #ffffff
- **Color** *colorBlack*: #000000
- **Color** *colorGray*: #7f7f7f
- **Color** *colorRoyal*: #4169e1
- **Color** *colorCoral*: #ff7f50
- **Color** *colorOrange*: #ffa500
- **Color** *colorRed*: #ff0000
- **Color** *colorMagenta*: #ff00ff
- **Color** *colorPurple*: #a020f0
- **Color** *colorGreen*: #00ff00
- **Color** *colorBlue*: #0000ff
- **Color** *colorPink*: #ff69b4
- **Color** *colorYellow*: #ffff00

## API Calls

API calls are JSON objects that are used to call a function within the game. What function is called is determined by its `type` field. Parameters are also passed as JSON fields. An example for an API call for drawing a spinning regular pentagon:

```json
{"type": "DrawPoly", "pos": "basePos", "sides": 5, "radius": 5.5, "stroke": 1.0, "color": "colorAccent", "rotation": "rad(fau_time * 90)"}
```

Parameters can either be constant or a formula. For example, the `rotation` field contains a formula for calculating the rotation based on game time, which is the standard way to animate shapes. What functions can be used inside formulas is defined in the chapter [Functions](#functions). Other usable math functions and operators can be found [here](https://yardanico.github.io/nim-mathexpr/mathexpr.html#what-is-supportedqmark). Formulas are usable for vectors, ints and floats. In the case of vectors, the formula is applied to each coordinate separately. Formulas cannot be used for colors, but colors can reference a predefined color by name. Otherwise, colors can only use hexadecimal notation (e.g. `#ff0000` for red). The alpha channel is added as two additional hexadecimal digits after the color (e.g. `#ff00007f` for half-transparent red), if not present the color is assumed to be fully opaque.

Fields that have a default value can be omitted from the call.

### Setters

#### SetFloat

Sets a float variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **float** *value*: The value to set the variable to.

#### SetVec2

Sets a 2D vector variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **Vec2** *value*: The value to set the variable to.

#### SetColor

Sets a color variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **Color** *value*: The color in hexadecimal notation (e.g. "#ff0000").

### Flow control

#### Condition

Defines a condition. If the condition is met, the *then* block is executed, otherwise the *else* block is executed.

- **bool** *condition*: The condition under which the *then* block will be executed.
- **Array** *then*: An array of calls to execute if the condition evaluates to *true*.
- **Array** *else*: An array of calls to execute if the condition evaluates to *false*.

#### Iterate

Iterates over a range with an iterator variable. The iterator is incremented by 1 each iteration until it reaches a maximum value.

- **string** *iterator*: The name of the iterator variable that will hold the position within the range.
- **int** *startValue*: The value at which the iterator starts. Must be less than *endValue*.
- **int** *endValue*: The value the iterator must reach to end the loop. Cannot be modified after entering the loop. The iterator will have this value during its last iteration.
- **Array** *body*: An array of calls to execute each iteration.

#### Repeat

Repeats an array of calls while a condition is met.

- **bool** *condition*: The condition than must be met to execute the *body*.
- **Array** *body*: An array of calls that will be executed repeatedly as long as the condition is met.

#### Break

Breaks out of the current loop. Stops execution if there is no current loop.

#### Return

Breaks out of all loops and stops execution.

### Drawing

#### DrawFft

I don't know what it does, and it is never used in the base game. (TODO do more testing)

- **Vec2** *pos*:
- **float** *radius*: (Default: *px(90)*)
- **float** *length*: (Default: *8*)
- **Color** *color*: (Default: *colorWhite*)

#### DrawTiles

Draws the playing field. Should only be used inside levels. (TODO coming soon)

#### DrawTilesFft

Draws the playing field. Should only be used inside levels. (TODO coming soon)

#### DrawTilesSquare

Draws the playing field. Should only be used inside levels. (TODO coming soon)

- **Color** *col1*: (Default: *colorWhite*)
- **Color** *col2*: (Default: *colorBlue*)

#### DrawBackground

Draws a single color background.

- **Color** *col*: The color of the background.

#### DrawStripes

Draws construction-tape-like stripes.

- **Color** *col1*: Background color. (Default: *colorPink*)
- **Color** *col2*: Stripe color. (Default: *colorPink* with 20% *colorWhite*)
- **float** *angle*: The angle of the stripes. (Default: *rad(135)*)

#### DrawBeatSquare

- **Color** *col*: (Default: *colorPink* with 70% *colorWhite*)

#### DrawBeatAlt

- **Color** *col*:

#### DrawTriSquare

Draws regular polygons in a circle around a position.

- **Vec2** *pos*: The position to draw the polygons around.
- **Color** *col*: The color of the polygons.
- **float** *len*: How far away the polygons are from the position.
- **float** *rad*: The size of the polygons.
- **float** *offset*: Additional rotation around the target position applied to each polygon. (Default: *rad(45)*)
- **int** *amount*: The number of polygons to draw. (Default: *4*)
- **int** *sides*: How many sides each polygon has. (Default: *3*)
- **float** *shapeOffset*: Additional rotation applied to each polygon around its own center. (Default: *rad(0)*)

#### DrawSpin

Draws stripes radially from the center. (TODO better explanation)

- **Color** *col1*: The first color.
- **Color** *col2*: The second color.
- **int** *blades*: The number of stripes to draw. (Default: *10*)

#### DrawSpinGradient

Draws a "fan" of triangles. (TODO better explanation)

- **Vec2** *pos*: The position to center the fan on.
- **Color** *col1*: The inner color of the triangles.
- **Color** *col2*: The outer color of the triangles.
- **float** *len*: The radius of the fan. (Default: *5*)
- **int** *blades*: The number of triangles that the fan is made of. (Default: *10*)
- **int** *spacing*: How often a triangle occurs. (Default: *2*)

#### DrawSpinShape

Only works inside levels. (TODO coming soon)

- **Color** *col1*:
- **Color** *col2*:
- **int** *sides*: (Default: *4*)
- **float** *rad*: (Default: *2.5*)
- **float** *turnSpeed*: (Default: *rad(19)*)
- **int** *rads*: (Default: *6*)
- **int** *radsides*: (Default: *4*)
- **float** *radOff*: (Default: *7*)
- **float** *radrad*: (Default: *1.3*)
- **float** *radrotscl*: (Default: *0.25*)

#### DrawShapeBack

Draws concentric polygons of alternating colors around the center.

- **Color** *col1*: The first color.
- **Color** *col2*: The second color.
- **int** *sides*: How many sides the polygons have. (Default: *4*)
- **float** *spacing*: The distance between each polygon "ring". (Default: *2.5*)
- **float** *angle*: The angle of the polygon. (Default: *rad(90)*)

#### DrawFadeShapes

Only works inside levels. (TODO coming soon)

- **Color** *col*:

#### DrawRain

Only works inside levels. (TODO coming soon)

- **int** *amount*: (Default: *80*)

#### DrawPetals

Only works inside levels. (TODO coming soon)

#### DrawSkats

Only works inside levels. (TODO coming soon)

#### DrawClouds

Only works inside levels. (TODO coming soon)

- **Color** *col*: (Default: *colorWhite*)

#### DrawLongClouds

Only works inside levels. (TODO coming soon)

- **Color** *col*: (Default: *colorWhite*)

#### DrawStars

Only works inside levels. (TODO coming soon)

- **Color** *col*: (Default: *colorWhite*)
- **Color** *flash*: (Default: *colorWhite*)
- **int** *amount*: (Default: *40*)
- **int** *seed*: (Default: *1*)

#### DrawTris

Only works inside levels. (TODO coming soon)

- **Color** *col1*: (Default: *colorWhite*)
- **Color** *col2*: (Default: *colorWhite*)
- **int** *amount*: (Default: *50*)
- **int** *seed*: (Default: *1*)

#### DrawBounceSquares

Only works inside levels. (TODO coming soon)

- **Color** *col*: (Default: *colorWhite*)

#### DrawCircles

Draws circles in random sizes that move around the screen in random directions. This effect is used for Mono, Oct and Sei.

- **Color** *col*: The color of the circles. (Default: *colorWhite*)
- **float** *time*: The circles will move if you put in a value that changes over time. (Default: *state_time*)
- **int** *amount*: The number of circles to draw. (Default: *50*)
- **int** *seed*: The random seed. (Default: *1*)
- **float** *minSize*: The smallest size a circle can be. (Default: *2*)
- **float** *maxSize*: The largest size a circle can be. (Default: *7*)
- **float** *moveSpeed*: The speed at which the circles move. (Default: *0.2*)

#### DrawRadTris

Draws triangles in random sizes that point away from the center and move around the screen in random directions. This effect is used for Crawler.

- **Color** *col*: The color of the triangles. (Default: *colorWhite*)
- **float** *time*: The triangles will move if you put in a value that changes over time. (Default: *state_time*)
- **int** *amount*: The number of triangles to draw (Default: *50*)
- **int** *seed*: The random seed. (Default: *1*)

#### DrawMissiles

Draws moving circles with a trail of smaller circles ("missiles"). This effect is used for Zenith.

- **Color** *col*: The color of the circles. (Default: *colorWhite*)
- **float** *time*: The circles will move if you put in a value that changes over time. (Default: *state_time*)
- **int** *amount*: The number of circles to draw (not including the trailing circles). (Default: *50*)
- **int** *seed*: The random seed. (Default: *1*)

#### DrawFallSquares

Draws squares that fall down while spinning and changing color. This effect is used for Quad.

- **Color** *col1*: The initial color of the squares. (Default: *colorWhite*)
- **Color** *col2*: The color the squares change to over their lifetime. (Default: *colorWhite*)
- **float** *time*: The squares will move if you put in a value that changes over time. (Default: *state_time*)
- **int** *amount*: The number of squares to draw. (Default: *50*)

#### DrawFlame

Draws circles that move upwards while becoming smaller and changing color. This effect is used for Oxynoe.

- **Color** *col1*: The initial color of the circles. (Default: *colorWhite*)
- **Color** *col2*: The color the circles change to. (Default: *colorWhite*)
- **float** *time*: The circles will move if you put in a value that changes over time. (Default: *state_time*)
- **int** *amount*: The number of circles to draw. (Default: *80*)

#### DrawSquares

Draws squares that slowly move around the screen and periodically shrink and grow. This effect is used for Alpha.

- **Color** *col*: The color of the squares. (Default: *colorWhite*)
- **float** *time*: The squares will move if you put in a value that changes over time. (Default: *state_time*)
- **int** *amount*: The number of squares to draw. (Default: *50*)
- **int** *seed*: The random seed. (Default: *2*)

#### DrawRoundLine

Draws a line with rounded endpoints.

- **Vec2** *pos*: The position of the midpoint of the line.
- **float** *angle*: The angle of the line.
- **float** *len*: The length of the line.
- **Color** *color*: The color of the line. (Default: *colorWhite*)
- **float** *stroke*: The thickness of the line. (Default: *1*)

#### DrawLines

Draws rounded lines that move around slightly (looks a bit like rays of light).

- **Color** *col*: The color of the lines. (Default: *colorWhite*)
- **int** *seed*: The random seed. (Default: *1*)
- **int** *amount*: The number of lines to draw. (Default: *30*)
- **float** *angle*: The angle at which to draw the lines. (Default: *rad(45)*)

#### DrawRadLines

Draws rounded lines pointing at the center of the screen that move around slightly.

- **Color** *col*: The color of the lines. (Default: *colorWhite*)
- **int** *seed*: The random seed. (Default: *6*)
- **int** *amount*: The number of lines to draw. (Default: *40*)
- **float** *stroke*: The thickness of the lines. (Default: *0.25*)
- **float** *posScl*: How far away the lines are from the center on average. A higher value means the lines are further away. (Default: *1*)
- **float** *lenScl*: How long the lines are. (Default: *1*)

#### DrawRadCircles

Draws circles in random sizes scattered around the center of the screen.

- **Color** *col*: The color of the circles. (Default: *colorWhite*)
- **int** *seed*: The random seed. (Default: *7*)
- **int** *amount*: The number of circles to draw. (Default: *40*)
- **float** *fin*: How far away the circles are from the center on average. Also scales the circles. (Default: *0.5*)

#### DrawSpikes

Draws rounded lines pointing to a position. The angle between all lines is the same.

- **Vec2** *pos*: The position the lines will point to.
- **Color** *col*: The color of the lines.
- **int** *amount*: The number of lines to draw. (Default: *10*)
- **float** *offset*: How far away the midpoint of each line is from the targeted position. (Default: *8*)
- **float** *len*: The length of the line. (Default: *3*)
- **float** *angleOffset*: Additional rotation around the target position applied to each line. (Default: *0*)

#### DrawGradient

Draws a gradient across the screen.

- **Color** *col1*: The color of the bottom left corner. (Default: *colorClear*)
- **Color** *col2*: The color of the bottom right corner. (Default: *colorClear*)
- **Color** *col3*: The color of the top right corner. (Default: *colorClear*)
- **Color** *col4*: The color of the top left corner. (Default: *colorClear*)

#### DrawVertGradient

Draws a vertical gradient.

- **Color** *col1*: The bottom color. (Default: *colorClear*)
- **Color** *col2*: The top color. (Default: *colorClear*)

#### DrawZoom

Draws concentric polygons around the center of the screen that increase in thickness further out.

- **Color** *col*: The color of the polygons. (Default: *colorWhite*)
- **float** *offset*: The offset of the first square from the center. Periodic. (TODO explain that better) (Default: *0*)
- **int** *amount*: The number of polygons to draw. (Default: *10*)
- **int** *sides*: The number of sides the polygon will have. (Default: *4*)

#### DrawFadeOut

The screen becomes light blue from the top left corner. This effect is used to transition between the menu and levels.

- **float** *time*: The screen will move if you put in a value that changes over time.

#### DrawFadeIn

A light blue screen disappears into the bottom right corner. This effect is used to transition between the menu and levels.

- **float** *time*: The circles will move if you put in a value that changes over time. The value should change in reverse (?).

#### DrawSpace

Draws many stripes pointing towards the center. (TODO check later, this probably does needs state_time)

- **Color** *col*: The color of the stripes.

#### DrawFillPoly

Draws a filled polygon.

- **Vec2** *pos*: The position of the center of the polygon.
- **int** *sides*: The number of sides the polygon has.
- **float** *radius*: The radius of the polygon.
- **float** *rotation*: The rotation of the polygon. (Default: *0*)
- **Color** *color*: The color of the polygon. (Default: *colorWhite*)
- **float** *z*: The z layer of the polygon. (Default: *0*)

#### DrawPoly

Draws a polygon outline.

- **Vec2** *pos*: The position of the center of the polygon.
- **int** *sides*: The number of sides the polygon has.
- **float** *radius*: The radius of the polygon.
- **float** *rotation*: The rotation of the polygon. (Default: *0*)
- **float** *stroke*: The line thickness of the polygon. (Default: *px(1)*)
- **Color** *color*: The color of the polygon. (Default: *colorWhite*)
- **float** *z*: The z layer of the polygon. (Default: *0*)

#### DrawUnit

Draws the unit's splash image.

- **Vec2** *pos*: Where to draw the unit.
- **Vec2** *scl*: Scale of the unit.  (Default: *vec2(1, 1)*)
- **Color** *color*: Color of the unit. (Default: *colorWhite*)
- **string** *part*: Suffix of the texture file to draw (e.g. *"-glow"* to draw *"mono-glow.png"*). (Default: *""*)

#### DrawBloom

Draws one or more patterns with bloom enabled.

- **Array** *body*: An array of draw calls to be drawn with bloom anabled.
