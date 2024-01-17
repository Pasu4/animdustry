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
- **vec2** *getScl(base)*: Used for displaying the unit portrait when rolling / clicking on a unit in the menu. Returns a scaling vector dependent on the size of the screen and the time until the unit appears.
- **vec2** *hoverOffset(scl, offset = 0)*: Used for displaying the unit portrait when rolling / clicking on a unit in the menu. Returns a displacement vector that is used to slightly move the unit up and down periodically.
- **vec2** *vec2(x, y)*: Constructs a 2D vector from x and y components.

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

- **vec2** *basePos*: The base position of the unit portrait.
- **vec2** *_getScl*: Calls *getScl(0.175)* (default value).
- **vec2** *_hoverOffset*: Calls *hoverOffset(0.65, 0)* (default value).
- **vec2** *playerPos*: Last known player position.

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
- **vec2** *value*: The value to set the variable to.

### SetColor

Sets a color variable that is accessible from anywhere.

- **string** *name*: The name of the variable to be set.
- **Color** *value*: The color in hexadecimal notation (e.g. "#ff0000").

### DrawFft

### DrawTiles

### DrawTilesFft

### DrawStripes

Draws stripes on the screen.

- **Color** *col1*: Background color. (Default: *colorPink*)
- **Color** *col2*: Stripe color. (Default: *colorPink* with 20% *colorWhite*)
- **float** *angle*: The angle of the stripes. (Default: *rad(135)*)
