import os, vars, types, strformat, core, fau/assets, std/json, std/strutils
import mathexpr
import jsonapi, patterns

let
  dataDir = getSaveDir("animdustry")
  modDir = dataDir / "mods/"

var
  drawEval = newEvaluator()
  mapEval = newEvaluator()

proc loadMods* =
  echo "Loading mods from ", modDir
  if dirExists(modDir):
    for kind, modPath in walkDir(modDir):
      echo &"Found {kind} {modPath}"
      if kind == pcDir and fileExists(modPath / "mod.json"):
        var modName, modAuthor, modNamespace: string
        # Remove try-except so the user actually gets an error message instead of the mod not loading
        # try: 
        let
          modNode = parseJson(readFile(modPath / "mod.json"))
        modName = modNode["name"].getStr()
        modAuthor = modNode["author"].getStr()
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
          unitSpritePath = modPath / "unitSprites"
          procedurePath = modPath / "procedures"
        
        echo &"Loading {modName} by {modAuthor}"

        # Units
        if dirExists(unitPath):
          for fileType, filePath in walkDir(unitPath):
            if fileType == pcFile and filePath.endsWith(".json"):
              #region Parse unit
              # Remove try-except so the user actually gets an error message instead of the mod not loading
              # try:
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
              # TODO abilityProc

              allUnits.add(parsedUnit)
              unlockableUnits.add(parsedUnit)
              # except JsonParsingError:
              #   echo "Could not parse file ", filePath
              # except KeyError:
              #   echo &"Could not load unit: {getCurrentExceptionMsg()}"
              #endregion
        if dirExists(procedurePath):
          for fileType, filePath in walkDir(unitPath):
            if fileType == pcFile and filePath.endsWith(".json"):
              #region Parse procedure
              let
                procNode = parseJson(readFile(filePath))
                procName = modNamespace & "::" & procNode["name"].getStr()
                paramNodes = procNode["parameters"].getElems()
                procedure = Procedure(
                  script: getScript(procNode["script"].getElems())
                )
              # Parse default parameters
              var floats, colors: Table
              for k, v in paramNodes:
                let str = v{"default"}.getStr("")
                if str.startsWith():
                  colors[k] = str
                elif not str.len == 0:
                  floats[k] = str
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
  creditsText &= "\n" & creditsTextEnd