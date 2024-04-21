> [!Warning]
> The contents of this document are not yet updated.

# Documentation

## Folder structure

A mod is a folder containing files. This folder must be placed in the `mods` folder of the mod loader. The location of this folder depends on your operating system:

- Windows: `%APPDATA%\animdustry\mods`
- Linux: `~/.config/animdustry/mods`
- Android: `/storage/emulated/0/Android/data/io.anuke.animdustry/files/mods`

If the folder does not exist, you can create it, otherwise it will be created automatically on first startup of the mod loader.

The folder structure of a mod is as follows:

```
modfolder
├── mod.json
├── credits.txt
├── maps
│   └── exampleMap.json
├── music
│   └── exampleMusic.ogg
├── sprites
│   └── exampleSprite.png
├── scripts
│   ├── exampleScript.js
│   └── init.js
├── units
│   └── exampleUnit.json
├── unitSplashes
│   └── exampleUnit.png
└── unitSprites
    ├── exampleUnit-angery.png
    ├── exampleUnit-happy.png
    ├── exampleUnit-hit.png
    └── exampleUnit.png
```

- **mod.json:** Contains information about the mod.
- **credits.txt:** Additional credits added to the credits of the game. Credits will be auto-generated if this file is missing.
- **maps:** Contains the playable maps this mod adds.
- **music:** Contains the music for the maps. All music files must be OGG files.
- **sprites:** Contains sprites for bullets and enemies.
- **scripts:** Contains scripts that will be executed on startup.
- **units:** Contains unit scripts. The name of a file should match the name of the unit.
- **unitSplashes:** Contains the unit splashes. Unit splashes must be named like the unit they belong to.
- **unitSprites:** Contains in-game sprites for the units.

An example of a mod can be found [here](https://github.com/Pasu4/animdustry-mod-template).

## mod.json

A `mod.json` or `mod.hjson` file must be placed in the root folder of the mod. It is what tells the mod loader that this folder contains a mod. The content of the file is as follows:

```json
{
    "name": "The name of your mod",
    "namespace": "example",
    "author": "You",
    "description": "Description of your mod",
    "enabled": true,
    "debug": false,
    "legacy": false
}
```

- **name:** The name of your mod.
- **namespace:** The namespace of your mod. Used to organize procedures.
- **author:** The main author of the mod. Other mentions can be placed in *credits.txt*.
- **description:** The description of your mod. Currently does absolutely nothing.
- **enabled:** Whether the mod should be loaded. Defaults to `true`.
- **debug:** Whether the mod is in debug mode. Debug mode activates some features that are useful for debugging. Defaults to `false`.
- **legacy:** Whether this mod is using the legacy JSON API. Should be `false` if you are making a JavaScript mod. Defaults to `false`.

## Custom Units

Unit scripts describe how a unit is drawn and how it interacts with the game. To define a unit, first place a JSON or Hjson file with the same name as your unit in the `units` folder. Its contents should look like this:

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

- **name:** The internal name of the unit. Used for loading files. Must be a valid JavaScript variable name.
- **title:** The title of the unit displayed at the top of the screen when it is rolled or clicked in the menu.
- **subtitle:** The subtitle, displayed below the title in smaller letters. Usually used for a short description of the unit.
- **abilityDesc:** A description of the unit's ability, displayed in the bottom right corner. May also be used for other descriptions.
- **abilityReload:** How many turns it takes for the unit's ability to activate.
- **unmoving:** If the unit can move. Only used by Boulder in the base game. May be omitted.
- **draw:** An array of draw calls to execute each time the unit splash is drawn. More about draw calls in the chapter [API Calls](#api-calls).
- **abilityProc:** An array of function calls to execute when the unit's ability is activated.

To add a splash image to your unit, place an image file with the same name as your unit into the `unitSplashes` folder. To add in-game sprites of your unit, place the files `example.png` and `example-hit.png` in the `unitSprites` folder (replace "example" with the name of your unit). Those two files must exist for the unit to display properly. Additionally, an `example-angery.png` (not a typo) and `example-happy.png` file can be placed in the folder as well. The `-angery` sprite is displayed when the player misses a beat, and the `-happy` sprite is displayed one second before a level ends.

## Custom Maps

Map scripts describe a playable level in the game. To add a custom map to the game, place a JSON or Hjson file into the `maps` folder. The contents of the file should look like this:

```json
{
    "name": "boss1",
    "songName": "Anuke - Boss 1",
    "music": "boss1",
    "bpm": 100.0,
    "beatOffset": 0.0,
    "maxHits": 10,
    "copperAmount": 8,
    "fadeColor": "fa874c",
    "alwaysUnlocked": true,
    "drawPixel": [
        {"type": "DrawStripes", "col1": "#19191c", "col2": "#ab8711"},
        {"type": "DrawBeatSquare", "col": "#f25555"}
    ],
    "draw": [
        {"type": "DrawTiles"}
    ],
    "update": [
        {"type": "Condition", "condition": "state_newTurn", "then": [
            {"type": "Turns", "fromTurn": 7, "toTurn": 23, "interval": 4, "body": [
                {"type": "Formation", "name": "d4edge", "iterator": "v", "body": [
                    {"type": "MakeDelayBulletWarn", "pos": "playerPos + v * 2", "dir": "-v"}
                ]}
            ]}
        ]}
    ]
}
```

- **name:** The internal name of the map. Must be a valid JavaScript variable name.
- **songName:** The name of the song that is displayed in the menu.
- **music:** The name of the music file without the file extension.
- **bpm:** The BPM (beats per minute) of the song.
- **beatOffset:** The music offset in beats. Used if the start of the music is misaligned with the beats.
- **maxHits:** How often the player needs to be hit to fail the map.
- **copperAmount:** The amount of copper the player will receive upon beating the level. How much copper the player actually gets is determined by how well they did in the level and if they have beaten the level before.
- **fadeColor:** (TODO test)
- **alwaysUnlocked:** If true, the map can be played without unlocking all previous maps. Optional.
- **drawPixel:** Script that draws the background.
- **draw:** Script that draws the playing field.
- **update:** Script that spawns enemies, obstacles, etc.

## Procedures

Procedures are used the same way as [API calls](#api-calls). They are placed as JSON or Hjson files in the *procedures* folder. They are called by putting the name of the procedure into the *type* field. Parameters are passed the same way as well. An example of a procedure:

```json
{
    "name": "Example",
    "parameters": [
        {"name": "_param1", "default": 1.0},
        {"name": "_param2"},
        {"name": "_col1", "default": "#ff0000"}
    ],
    "script": [
        {"type": "Comment", "comment": "Useful function here."}
    ]
}
```

- **name:** The name the procedure is referenced with.
- **parameters:** The parameters the procedure accepts.
- **script:** An array of calls that is executed when the procedure is called.

This procedure would be called from another script like so:

```json
{"type": "Example", "_param1": 2.0, "_param2": 42.0}
```

You can also call procedures from another mod. To do that, you have to qualify the procedure you want to call with the namespace of the mod it is from, like so:

```json
{"type": "utils::Example", "_param1": 2.0, "_param2": 42.0}
```

The parameters of the called procedure are stored as global variables, which means they are accessible from outside the procedure. Since all variables are global, even those used internally can be accessed (this way you can make a return value).

> [!IMPORTANT]
> For technical reasons, color literals passed as parameters to a procedure **must** be prefixed with the `#` character!

A procedure can also call another procedure, even itself recursively. Keep in mind though that since all variables are global, this might overwrite other variables used in the procedure.

Procedures may have the same name as API calls, but the only way to call them then is by qualifying them with their namespace.

The `Return` call always jumps to the end of the current procedure.

### Init procedure

If the mod contains a procedure with the name `Init` (case-sensitive), it is automatically called with default arguments when loading the mod. Use it to set constants or initialize variables for use in other scripts. Example:

```json
{
    "name": "Init",
    "script": [
        {"type": "SetColor", "name": "colorWClear", "value": "#ffffff00"},

        {"type": "SetFloat", "name": "objFade", "value": 0}
    ]
}
```
