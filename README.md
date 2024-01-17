![](assets-raw/icon.png)

# Animdustry Mod Loader

A modloader for the anime gacha bullet hell rhythm game by Anuke.

[Downloads for windows/linux/android are available on the releases page.](https://github.com/Pasu4/animdustry/releases)

# compiling

For information on compiling, please refer to [the original repository](https://github.com/Anuken/animdustry/blob/master/README.md#compiling).

# credits

Original game by Anuke

Modloader programming and documentation by Pasu4

music used:

- [Aritus - For You](https://soundcloud.com/aritusmusic/4you)
- [PYC - Stoplight](https://soundcloud.com/pycmusic/stoplight)
- [Keptor's Room - Bright 79](https://soundcloud.com/topazeclub/bright-79)
- [Aritus - Pina Colada II](https://soundcloud.com/aritusmusic/pina-colada-ii-final)
- [ADRIANWAVE - Peach Beach](https://soundcloud.com/adrianwave/peach-beach)

# Documentation

## Functions

- **float** *px(val)*: Turns pixel units into world units.
- **Vec2** *getScl(base)*: Used for displaying the unit portrait when rolling / clicking on a unit in the menu. Returns a scaling vector dependent on the size of the screen and the time until the unit appears.
- **Vec2** *hoverOffset(scl, offset = 0)*: Used for displaying the unit portrait when rolling / clicking on a unit in the menu. Returns a displacement vector that is used to slightly move the unit up and down periodically.
- **Vec2** *vec2(x, y)*: Constructs a 2D vector from x and y components.

## Variables

- **float** *state_secs*: Smoothed position of the music track in seconds.
- **float** *state_lastSecs*: Last "discrete" music track position, internally used.
- **float** *state_time*: Smooth game time, may not necessarily match seconds. Visuals only!
- **float** *state_rawBeat*: Raw beat calculated based on music position.
- **float** *state_moveBeat*: Beat calculated as countdown after a music beat happens. Smoother, but less precise.
- **float** *state_hitTime*: Snaps to 1 when player is hit for health animation.
- **float** *state_healTime*: Snaps to 1 when player is healed.
- **float** *state_points*: Points awarded based on various events.
- **float** *state_turn*: Beats that have passed total.
- **float** *state_hits*: The number of times the player has been hit this map. (?)
- **float** *state_totalHits*: Same as *state_hits*, probably.
- **float** *state_misses*: The number of times the player has missed an input this map. (?)
- **float** *fau_time*: The global time that is independent of the current beatmap.

- **Vec2** *basePos*: The base position of the unit portrait.
- **Vec2** *_getScl*: Calls *getScl(0.175)* (default value).
- **Vec2** *_hoverOffset*: Calls *hoverOffset(0.65, 0)* (default value).
- **Vec2** *playerPos*: Last known player position.

- **Color** *shadowColor*
- **Color** *colorAccent*
- **Color** *colorUi*
- **Color** *colorUiDark*
- **Color** *colorHit*
- **Color** *colorHeal*
- **Color** *colorClear*
- **Color** *colorWhite*
- **Color** *colorBlack*
- **Color** *colorGray*
- **Color** *colorRoyal*
- **Color** *colorCoral*
- **Color** *colorOrange*
- **Color** *colorRed*
- **Color** *colorMagenta*
- **Color** *colorPurple*
- **Color** *colorGreen*
- **Color** *colorBlue*
- **Color** *colorPink*
- **Color** *colorYellow*

## Calls

### SetFloat

Sets a float variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **float** *value*: The value to set the variable to.

### SetVec2

Sets a 2D vector variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **Vec2** *value*: The value to set the variable to.

### SetColor

Sets a color variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **Color** *value*: The color in hexadecimal notation (e.g. "#ff0000").

### DrawFft

- **Vec2** *pos*:
- **float** *radius*: (Default: *px(90)*)
- **float** *length*: (Default: *8*)
- **Color** *color*: (Default: *colorWhite*)

### DrawTiles

### DrawTilesFft

### DrawTilesSquare

- **Color** *col1*: (Default: *colorWhite*)
- **Color** *col2*: (Default: *colorBlue*)

### DrawBackground

- **Color** *col*: 

### DrawStripes

Draws stripes on the screen.

- **Color** *col1*: Background color. (Default: *colorPink*)
- **Color** *col2*: Stripe color. (Default: *colorPink* with 20% *colorWhite*)
- **float** *angle*: The angle of the stripes. (Default: *rad(135)*)

### DrawBeatSquare

- **Color** *col*: (Default: *colorPink* with 70% *colorWhite*)

### DrawBeatAlt

- **Color** *col*:

### DrawTriSquare

- **Vec2** *pos*:
- **Color** *col*:
- **float** *len*:
- **float** *rad*:
- **float** *offset*:(Default: *rad(45)*)
- **int** *amount*:(Default: *4*)
- **int** *sides*:(Default: *3*)
- **float** *shapeOffset*:(Default: *rad(0)*)

### DrawSpin

- **Color** *col1*:
- **Color** *col2*:
- **int** *blades*: (Default: *10*)

### DrawSpinGradient

- **Vec2** *pos*:
- **Color** *col1*:
- **Color** *col2*:
- **float** *len*: (Default: *5*)
- **int** *blades*: (Default: *10*)
- **int** *spacing*: (Default: *2*)

### DrawSpinShape

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

### DrawShapeBack

- **Color** *col1*:
- **Color** *col2*:
- **int** *sides*: (Default: *4*)
- **float** *spacing*: (Default: *2.5*)
- **float** *angle*: (Default: *rad(90)*)

### DrawFadeShapes

- **Color** *col*:

### DrawRain

- **int** *amount*: (Default: *80*)

### DrawPetals

### DrawSkats

### DrawClouds

- **Color** *col*: (Default: *colorWhite*)

### DrawLongClouds

- **Color** *col*: (Default: *colorWhite*)

### DrawStars

- **Color** *col*: (Default: *colorWhite*)
- **Color** *flash*: (Default: *colorWhite*)
- **int** *amount*: (Default: *40*)
- **int** *seed*: (Default: *1*)

### DrawTris

- **Color** *col1*: (Default: *colorWhite*)
- **Color** *col2*: (Default: *colorWhite*)
- **int** *amount*: (Default: *50*)
- **int** *seed*: (Default: *1*)

### DrawBounceSquares

- **Color** *col*: (Default: *colorWhite*)

### DrawCircles

- **Color** *col*: (Default: *colorWhite*)
- **float** *time*: (Default: *state_time*)
- **int** *amount*: (Default: *50*)
- **int** *seed*: (Default: *1*)
- **float** *minSize*: (Default: *2*)
- **float** *maxSize*: (Default: *7*)
- **float** *moveSpeed*: (Default: *0.2*)

### DrawRadTris

- **Color** *col*: (Default: *colorWhite*)
- **float** *time*: (Default: *state_time*)
- **int** *amount*: (Default: *50*)
- **int** *seed*: (Default: *1*)

### DrawMissiles

- **Color** *col*: (Default: *colorWhite*)
- **float** *time*: (Default: *state_time*)
- **int** *amount*: (Default: *50*)
- **int** *seed*: (Default: *1*)

### DrawFallSquares

- **Color** *col1*: (Default: *colorWhite*)
- **Color** *col2*: (Default: *colorWhite*)
- **float** *time*: (Default: *state_time*)
- **int** *amount*: (Default: *50*)

### DrawFlame

- **Color** *col1*: (Default: *colorWhite*)
- **Color** *col2*: (Default: *colorWhite*)
- **float** *time*: (Default: *state_time*)
- **int** *amount*: (Default: *80*)

### DrawSquares

- **Color** *col*: (Default: *colorWhite*)
- **float** *time*: (Default: *state_time*)
- **int** *amount*: (Default: *50*)
- **int** *seed*: (Default: *2*)

### DrawRoundLine

- **Vec2** *pos*:
- **float** *angle*:
- **float** *len*:
- **Color** *color*: (Default: *colorWhite*)
- **float** *stroke*: (Default: *1*)

### DrawLines

- **Color** *col*: (Default: *colorWhite*)
- **int** *seed*: (Default: *1*)
- **int** *amount*: (Default: *30*)
- **float** *angle*: (Default: *rad(45)*)

### DrawRadLines

- **Color** *col*: (Default: *colorWhite*)
- **int** *seed*: (Default: *6*)
- **int** *amount*: (Default: *40*)
- **float** *stroke*: (Default: *0.25*)
- **float** *posScl*: (Default: *1*)
- **float** *lenScl*: (Default: *1*)

### DrawRadCircles

- **Color** *col*: (Default: *colorWhite*)
- **int** *seed*: (Default: *7*)
- **int** *amount*: (Default: *40*)
- **float** *fin*: (Default: *0.5*)

### DrawSpikes

- **Vec2** *pos*:
- **Color** *col*:
- **int** *amount*: (Default: *10*)
- **float** *offset*: (Default: *8*)
- **float** *len*: (Default: *3*)
- **float** *angleOffset*: (Default: *0*)

### DrawGradient

- **Color** *col1*: (Default: *colorClear*)
- **Color** *col2*: (Default: *colorClear*)
- **Color** *col3*: (Default: *colorClear*)
- **Color** *col4*: (Default: *colorClear*)

### DrawVertGradient

- **Color** *col1*: (Default: *colorClear*)
- **Color** *col2*: (Default: *colorClear*)

### DrawZoom

- **Color** *col*: (Default: *colorWhite*)
- **float** *offset*: (Default: *0*)
- **int** *amount*: (Default: *10*)
- **int** *sides*: (Default: *4*)

### DrawFadeOut

- **float** *time*:

### DrawFadeIn

- **float** *time*:

### DrawSpace

- **Color** *col*:

### DrawFillPoly

Draws a filled polygon.

- **Vec2** *pos*:
- **int** *sides*:
- **float** *radius*:
- **float** *rotation*: (Default: *0*)
- **Color** *color*: (Default: *colorWhite*)
- **float** *z*: (Default: *0*)

### DrawPoly

Draws a polygon outline.

- **Vec2** *pos*:
- **int** *sides*:
- **float** *radius*:
- **float** *rotation*: (Default: *0*)
- **float** *stroke*: (Default: *px(1)*)
- **Color** *color*: (Default: *colorWhite*)
- **float** *z*: (Default: *0*)

### DrawUnit

Draws a unit portrait.

- **Vec2** *pos*: Where to draw the unit.
- **Vec2** *scl*: Scale of the unit.  (Default: *vec2(1, 1)*)
- **Color** *color*: Color of the unit. (Default: *colorWhite*)
- **string** *part*: Suffix of the texture file to draw (e.g. *"-glow"* to draw *"mono-glow.png"*). (Default: *""*)

### DrawBloom

Draws one or more patterns with bloom enabled.

- **Array** *body*: An array of draw calls to be drawn with bloom anabled.
