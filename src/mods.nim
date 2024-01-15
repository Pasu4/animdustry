import os, vars, types, strformat, core, fau/assets, tables, msgpack4nim, msgpack4nim/msgpack4collection, std/json, std/strutils, std/sequtils
import mathexpr
import jsonapi

let
  dataDir = getSaveDir("animdustry")
  modDir = dataDir / "mods/"

var
  drawEval = newEvaluator()
  mapEval = newEvaluator()

proc loadMods* =
  #region Evaluators
  #endregion
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
        
        echo &"Loading {modName} by {modAuthor}"

        # Units
        if dirExists(unitPath):
          for fileType, filePath in walkDir(unitPath):
            if fileType == pcFile and filePath.endsWith(".json"):
              #region Parse unit
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
                parsedUnit.canAngery = fileExists(modPath / "unitSprites/" & unitName & "-angery.png")
                # TODO draw, abilityProc
                parsedUnit.draw = getUnitDraw(unitNode["draw"])

                allUnits.add(parsedUnit)
                unlockableUnits.add(parsedUnit)
              except JsonParsingError:
                echo "Could not parse file ", filePath
              except KeyError:
                echo &"Could not load unit: {getCurrentExceptionMsg()}"
              #endregion

        echo "Finished loading mods."
        echo "Unit count: ", allUnits.len
        echo "Unlockable: ", unlockableUnits.len
  else:
    echo "Mod folder does not exist, skipping"