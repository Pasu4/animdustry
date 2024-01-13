import os, vars, types, strformat, core, fau/assets, tables, msgpack4nim, msgpack4nim/msgpack4collection, std/json, std/strutils, std/sequtils

let 
  dataDir = getSaveDir("animdustry")
  dataFile = dataDir / "data.bin"
  modDir = dataDir / "mods/"
  settingsFile = dataDir / "settings.bin"

proc packType*[ByteStream](s: ByteStream, unit: Unit) =
  s.pack(if unit == nil: "nil" else: unit.name)

proc unpackType*[ByteStream](s: ByteStream, unit: var Unit) =
  var str: string
  s.unpack(str)

  if str == "nil":
    unit = nil
    return
  for other in allUnits:
    if other.name == str:
      unit = other
      return
  
  unit = unitMono

proc saveSettings* =
  try:
    dataDir.createDir()
    settingsFile.writeFile(pack(settings))
  except:
    echo &"Error: Failed to write settings: {getCurrentExceptionMsg()}"

proc loadSettings* =
  if fileExists(settingsFile):
    try:
      unpack(settingsFile.readFile, settings)
      echo "Loaded settings."
    except: echo &"Failed to load settings: {getCurrentExceptionMsg()}"

proc saveGame* =
  try:
    dataDir.createDir()
    dataFile.writeFile(pack(save))
  except:
    echo &"Error: Failed to write save data: {getCurrentExceptionMsg()}"

proc loadGame* =
  echo "Loading game from ", dataFile
  ## Loads game data from the save file. Does nothing if there is no data.
  if fileExists(dataFile):
    try:
      unpack(dataFile.readFile, save)
      echo "Loaded game state."
    except: echo &"Failed to load save state: {getCurrentExceptionMsg()}"

proc loadMods* =
  echo "Loading mods from ", modDir
  if dirExists(modDir):
    for kind, modPath in walkDir(modDir):
      echo &"Found {kind} {modPath}"
      if kind == pcDir and fileExists(modPath / "mod.json"):
        var modName, modAuthor : string
        try: 
          let
            modNode = parseJson(readFile(modPath / "mod.json"))
          modName = modNode["name"].getStr()
          modAuthor = modNode["author"].getStr()
          # TODO do something with description
        except JsonParsingError:
          echo "Could not parse mod ", modPath
          continue # Next mod
        except KeyError:
          echo &"Could not load mod: {getCurrentExceptionMsg()}"
          continue # Next mod
        
        let
          unitPath = modPath / "units"
          mapPath = modPath / "maps"
          unitSpritePath = modPath / "unitSprites"
        
        echo &"Loading mod {modName} by {modAuthor}"

        # Units
        if dirExists(unitPath):
          for fileType, filePath in walkDir(unitPath):
            if fileType == pcFile and filePath.endsWith(".json"):
              # Parse unit
              try:
                let
                  unitNode = parseJson(readFile(filePath))
                  unitName = unitNode["name"].getStr()
                  parsedUnit = Unit(
                    name: unitName,
                    title: unitNode{"title"}.getStr(&"-{unitName.toUpperAscii()}-"),
                    subtitle: unitNode{"subtitle"}.getStr(),
                    ability: unitNode{"abilityDesc"}.getStr(),
                    abilityReload: unitNode{"abilityReload"}.getInt(0),
                    unmoving: unitNode{"unmoving"}.getBool(false),
                    isModded: true,
                    modPath: modPath
                  )
                # TODO draw, abilityProc
                
                allUnits.add(parsedUnit)
                unlockableUnits.add(parsedUnit)
              except JsonParsingError:
                echo "Could not parse file ", filePath
              except KeyError:
                echo &"Could not load unit: {getCurrentExceptionMsg()}"

        echo "Finished loading mods."
        echo "Unit count: ", allUnits.len
        echo "Unlockable: ", unlockableUnits.len
  else:
    echo "Mod folder does not exist, skipping"
