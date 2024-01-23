import os, vars, types, strformat, core, fau/assets, std/json, std/strutils, std/tables
import jsonapi, patterns

let
  dataDir = getSaveDir("animdustry")
  modDir = 
    when defined(Android):
      "/storage/emulated/0/Android/data/io.anuke.animdustry/files/mods/"
    else:
      dataDir / "mods/"

proc loadMods* =
  echo "Loading mods from ", modDir
  if dirExists(modDir):
    for kind, modPath in walkDir(modDir):
      echo &"Found {kind} {modPath}"
      if kind == pcDir and fileExists(modPath / "mod.json"):
        # Remove try-except so the user actually gets an error message instead of the mod not loading
        # try: 
        let
          modNode = parseJson(readFile(modPath / "mod.json"))
          modName = modNode["name"].getStr()
          modAuthor = modNode["author"].getStr()
          modNamespace = modNode["namespace"].getStr()
        currentNamespace = modNamespace
        
        # TODO do something with description
        # except JsonParsingError:
        #   echo "Could not parse mod ", modPath
        #   continue # Next mod
        # except KeyError:
        #   echo &"Could not load mod: {getCurrentExceptionMsg()}"
        #   continue # Next mod
        
        let
          unitPath = modPath / "units"
          mapPath = modPath / "maps"
          procedurePath = modPath / "procedures"
        
        echo &"Loading {modName} by {modAuthor}"

        # Units
        if dirExists(unitPath):
          for fileType, filePath in walkDir(unitPath):
            if fileType == pcFile and filePath.endsWith(".json"):
              #region Parse unit
              # No try-except so the user actually gets an error message instead of the mod not loading
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
              parsedUnit.canAngery = fileExists(modPath / "unitSprites/" & unitName & "-angery.png")
              parsedUnit.canHappy = fileExists(modPath / "unitSprites/" & unitName & "-happy.png")

              parsedUnit.draw = getUnitDraw(unitNode["draw"])
              parsedUnit.abilityProc = getUnitAbility(unitNode["abilityProc"])

              allUnits.add(parsedUnit)
              unlockableUnits.add(parsedUnit)
              #endregion
        # Maps
        if dirExists(mapPath):
          for fileType, filePath in walkDir(mapPath):
            if fileType == pcFile and filePath.endsWith(".json"):
              #region Parse map
              let
                mapNode = parseJson(readFile(filePath))
                songName = mapNode["songName"].getStr()
                parsedMap = Beatmap(
                  songName: songName,
                  music: mapNode["music"].getStr(),
                  bpm: mapNode["bpm"].getFloat(),
                  beatOffset: mapNode["beatOffset"].getFloat(),
                  maxHits: mapNode["maxHits"].getInt(),
                  copperAmount: mapNode["copperAmount"].getInt(),
                  fadeColor: parseColor(mapNode["fadeColor"].getStr()), # Fau color

                  isModded: true,
                  modPath: modPath,
                  alwaysUnlocked: mapNode{"alwaysUnlocked"}.getBool()
                )

              parsedMap.drawPixel = getScript(mapNode["drawPixel"])
              parsedMap.draw = getScript(mapNode["draw"])
              parsedMap.update = getScript(mapNode["update"])

              allMaps.add(parsedMap)
              #endregion
        # Procedures
        if dirExists(procedurePath):
          for fileType, filePath in walkDir(procedurePath):
            if fileType == pcFile and filePath.endsWith(".json"):
              #region Parse procedure
              let
                procNode = parseJson(readFile(filePath))
                procName = modNamespace & "::" & procNode["name"].getStr()
                paramNodes = procNode["parameters"].getElems()
                procedure = Procedure(
                  script: getScript(procNode["script"], update = false)
                )
              # Parse default parameters
              var floats, colors: Table[string, string]
              for pn in paramNodes:
                let
                  key = pn["name"].getStr()
                  val = pn{"default"}.getStr("")
                if val.startsWith('#'):
                  colors[key] = val
                elif not val.len == 0:
                  floats[key] = val
              procedure.defaultFloats = floats
              procedure.defaultColors = colors
              procedures[procName] = procedure
              #endregion
        
        # Credits
        if fileExists(modPath / "credits.txt"):
          creditsText &= "\n" & readFile(modPath / "credits.txt") & "\n\n------\n"
        else:
          # Auto-generate credits
          creditsText &= &"\n- {modName} -\n\nMade by: {modAuthor}\n\n(Auto-generated credits)\n\n------\n"


    echo "Finished loading mods."
    echo "Unit count: ", allUnits.len
    echo "Unlockable: ", unlockableUnits.len
  else:
    echo "Mod folder does not exist, creating"
    createDir(modDir)

  # Finish credits
  creditsText = &"Your mod folder: {modDir}\n\n" & creditsText
  creditsText &= "\n" & creditsTextEnd