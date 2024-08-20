import os, vars, types, strformat, core, fau/assets, std/[json, strutils, sequtils, tables, httpclient, base64, uri]
import jsonapi, jsapi, apivars, patterns, hjson

type ModListEntry = object
  name*, id*, namespace*, repo*: string
  wip* = false
  dependencies*: seq[string]

let
  dataDir = getSaveDir("animdustry")
  modDir = 
    when defined(Android):
      "/storage/emulated/0/Android/data/io.anuke.animdustry/files/mods/"
    else:
      dataDir / "mods/"
var
  modErrorLog*: string
  modPaths*: Table[string, string]
  modList*: JsonNode
  modListLoaded* = false

template modError(filePath) =
  modErrorLog &= &"In {filePath[modDir.len..^1]}:\n{getCurrentExceptionMsg()}\n"
  mode = gmModError
  continue

# Downloads a json file from the latest release of the repository.
# If there is no latest release, downloads from head.
# TODO Use mod repo
proc downloadJsonFromGithub(client: HttpClient, repo, filepath: string, specificRef = ""): JsonNode =
  let
    parsedUri = parseUri(repo)
    path = parsedUri.path.split('/')
    releaseResponse = client.get(&"https://api.github.com/repos/{path[1]}/{path[2]}/releases/latest")
    latestRef = # HEAD if latest release is not found
      if specificRef.len != 0:
        specificRef
      elif releaseResponse.status.startsWith("200"):
        parseJson(releaseResponse.body())["tag_name"].getStr()
      else:
        "HEAD"
    fileUri = &"https://api.github.com/repos/{path[1]}/{path[2]}/contents/{filepath}?ref={latestRef}"
    json = parseJson(client.getContent(fileUri))
    content = base64.decode(json["content"].getStr())
    contentJson =
      if filepath.endsWith(".hjson"):
        parseJson(hjson2json(content))
      else:
        parseJson(content)
  return contentJson

proc fileExistsOnGithub(client: HttpClient, repo, filepath: string): bool =
  let
    parsedUri = parseUri(repo)
    path = parsedUri.path.split('/')
    apiUri = &"https://api.github.com/repos/{path[1]}/{path[2]}/contents/{filepath}"
  return client.get(apiUri).status.startsWith("200")

proc loadModList* =
  if modListLoaded:
    return
  modListLoaded = true

  # Fetch mods from their repositories
  var client = newHttpClient()
  try:
    echo "Fetching mod list"
    # var modListJson
    # TODO Remove once I have internet
    modList = parseJson("""
    {
      "updated": "2024-06-05T12:46:48Z",
      "mods": [
        {
          "name": "Crux",
          "namespace": "crux",
          "author": "Pasu4",
          "description": "Adds a map to the game. Work in progress.",
          "version": "0.1.0",
          "tags": [
            "map"
          ],
          "debug": false,
          "enabled": true,
          "repoName": "Pasu4/crux-mod",
          "repoOwner": "Pasu4",
          "repoUrl": "https://github.com/Pasu4/crux-mod",
          "downloadUrl": "https://api.github.com/repos/Pasu4/crux-mod/zipball",
          "creationDate": "2024-01-31T10:53:28Z",
          "lastUpdate": "2024-05-31T09:37:40Z"
        }
      ],
      "problems": {}
    }
    """)
    # Duplicate 9 times for testing
    for i in 0..9:
      modList["mods"].add(modList["mods"].getElems()[0])
    #[
    modList = client.downloadJsonFromGithub("https://github.com/Pasu4/animdustry-mods", "mod-list.json", "HEAD")
    for m in modList["mods"].getElems():
      try:
        echo "Fetching ", m["id"].getStr(), " from ", m["repo"].getStr()
        let
          modRepoUri = m["repo"].getStr()
          fileName = (if client.fileExistsOnGithub(modRepoUri, "mod.json"): "mod.json" else: "mod.hjson")
          modJson = client.downloadJsonFromGithub(modRepoUri, fileName)
          mle = ModListEntry(
            name: modJson["name"].getStr(),
            id: m["id"].getStr(),
            namespace: modJson["namespace"].getStr(),
            repo: modRepoUri,
            wip: modJson{"wip"}.getBool(false),
            dependencies: modJson{"dependencies"}.getElems().map(proc(j: JsonNode): string = j.getStr())
          )
        modList.add(mle)

      # except JsonParsingError, HjsonParsingError, KeyError:
      #   echo "Error parsing mod \"", m["id"].getStr(), "\": ", getCurrentExceptionMsg()
      except HttpRequestError, ProtocolError:
        echo getCurrentExceptionMsg()
    ]#
  finally:
    client.close()

proc loadMods* =
  var mainScriptPaths: Table[string, string] # Table of JS main scripts

  echo "Loading mods from ", modDir
  if dirExists(modDir):
    for kind, modPath in walkDir(modDir): # Walk through mods
      echo &"Found {kind} {modPath}"
      let isHjson = fileExists(modPath / "mod.hjson")
      if kind == pcDir and isHjson or fileExists(modPath / "mod.json"):
        var
          modName, modAuthor: string
          modLegacy: bool
        try:
          let
            modJson =
              if isHjson: hjson2json(readFile(modPath / "mod.hjson"))
              else: readFile(modPath / "mod.json")
            modNode = parseJson(modJson)
            modEnabled = modNode{"enabled"}.getBool(true)
            modDebug = modNode{"debug"}.getBool(false)
          
          modName = modNode["name"].getStr()
          modAuthor = modNode["author"].getStr()
          currentNamespace = modNode["namespace"].getStr()
          modLegacy = modNode{"legacy"}.getBool(false) # Legacy mods use JSON scripts instead of JavaScript

          modPaths[currentNamespace] = modPath

          if not modEnabled: continue
          if modLegacy:
            jsonapi.debugMode = jsonapi.debugMode or modDebug
          else:
            jsapi.debugMode = jsapi.debugMode or modDebug
          
          # TODO do something with description
        except JsonParsingError, HjsonParsingError, KeyError:
          echo &"Could not load mod {modPath}: {getCurrentExceptionMsg()}"
          let ext = (if isHjson: "hjson" else: "json")
          modErrorLog &= &"In {modPath[modDir.len..^1]}/mod.{ext}:\n{getCurrentExceptionMsg()}\n"
          mode = gmModError
          continue # Next mod
        
        let
          unitPath = modPath / "units"
          mapPath = modPath / "maps"
          procedurePath = modPath / "procedures"
          scriptPath = modPath / "scripts"
        
        echo &"Loading {modName} by {modAuthor}"

        if not modLegacy:
          # Add namespace
          addNamespace(currentNamespace)
        else:
          echo "Warning: Legacy mod."

        # Procedures
        if modLegacy and dirExists(procedurePath):
          for fileType, filePath in walkDir(procedurePath):
            if fileType == pcFile and (filePath.endsWith(".json") or filePath.endsWith(".hjson")):
              #region Parse procedure
              try:
                let procJson =
                  if filePath.endsWith(".hjson"):
                    hjson2json(readFile(filePath))
                  else:
                    readFile(filePath)
                let
                  procNode = parseJson(procJson)
                  procName = currentNamespace & "::" & procNode["name"].getStr()
                  paramNodes = procNode{"parameters"}.getElems(@[])
                  procedure = Procedure(
                    script: getScript(procNode["script"], update = false)
                  )
                # Parse default parameters
                var parameters: Table[string, string]
                for pn in paramNodes:
                  let
                    key = pn["name"].getStr()
                    val = pn{"default"}.getStr("")
                  if not val.len == 0:
                    parameters[key] = val
                procedure.defaultValues = parameters
                procedures[procName] = procedure
              except JsonParsingError, HjsonParsingError, KeyError:
                modError(filePath)
              #endregion
          # Call Init procedure
          if (currentNamespace & "::Init") in procedures:
            procedures[currentNamespace & "::Init"].script()
        elif dirExists(scriptPath):
          #region Load scripts
          # Update API
          updateJs(currentNamespace)

          # First, check if a 'init.js' file exists
          var filePath = scriptPath / "init.js"
          if fileExists(filePath):
            let script = readFile(scriptPath / "init.js")
            echo "Executing, ", filePath
            try:
              evalScriptJs(script)
            except JavaScriptError:
              modError(filePath)

          # Load all scripts
          for fileType, filePath in walkDir(scriptPath):
            # Load all scripts except 'init.js' (already loaded above) and '__api.js' (for function highlighting)
            if fileType == pcFile and filePath.endsWith(".js") and not (filePath[(scriptPath.len+1)..^1] in ["init.js", "__api.js"]):
              let script = readFile(filePath)
              echo "Executing ", filePath
              try:
                evalScriptJs(script)
              except JavaScriptError:
                modError(filePath)

          # Check if a 'main.js' file exists
          filePath = scriptPath / "main.js"
          if fileExists(filePath):
            # Add to list of main scripts
            mainScriptPaths[currentNamespace] = filePath
          #endregion

        # Units
        if dirExists(unitPath):
          for fileType, filePath in walkDir(unitPath):
            if fileType == pcFile and (filePath.endsWith(".json") or filePath.endsWith(".hjson")):
              #region Parse unit
              try:
                let unitJson =
                  if filePath.endsWith(".hjson"):
                    hjson2json(readFile(filePath))
                  else:
                    readFile(filePath)
                let
                  unitNode = parseJson(unitJson)
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

                if modLegacy:
                  parsedUnit.draw = getUnitDraw(unitNode["draw"])
                  parsedUnit.abilityProc = getUnitAbility(unitNode["abilityProc"])
                else:
                  parsedUnit.draw = getUnitDrawJs(currentNamespace, unitName & "_draw")
                  parsedUnit.abilityProc = getUnitAbilityJs(currentNamespace, unitName & "_ability")

                allUnits.add(parsedUnit)
                unlockableUnits.add(parsedUnit)
              except JsonParsingError, HjsonParsingError, KeyError:
                modError(filePath)
              #endregion

        # Maps
        if dirExists(mapPath):
          for fileType, filePath in walkDir(mapPath):
            if fileType == pcFile and (filePath.endsWith(".json") or filePath.endsWith(".hjson")):
              #region Parse map
              try:
                let mapJson =
                  if filePath.endsWith(".hjson"):
                    hjson2json(readFile(filePath))
                  else:
                    readFile(filePath)
                let
                  mapNode = parseJson(mapJson)
                  mapName = (if modLegacy: "" else: mapNode["name"].getStr())
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

                if modLegacy:
                  parsedMap.drawPixel = getScript(mapNode["drawPixel"])
                  parsedMap.draw = getScript(mapNode["draw"])
                  parsedMap.update = getScript(mapNode["update"])
                else:
                  if mapName.len == 0:
                    raise newException(JsonParsingError, "Missing 'name' field in map JSON.")
                  parsedMap.drawPixel = getScriptJs(currentNamespace, mapName & "_drawPixel")
                  parsedMap.draw = getScriptJs(currentNamespace, mapName & "_draw")
                  parsedMap.update = getScriptJs(currentNamespace, mapName & "_update")

                allMaps.add(parsedMap)
              except JsonParsingError, HjsonParsingError, KeyError:
                modError(filePath)
              #endregion

        # Credits
        if fileExists(modPath / "credits.txt"):
          creditsText &= "\n" & readFile(modPath / "credits.txt") & "\n\n------\n"
        else:
          # Auto-generate credits
          creditsText &= &"\n- {modName} -\n\nMade by: {modAuthor}\n\n(Auto-generated credits)\n\n------\n"

    # Execute main scripts
    echo "Running main scripts"
    for namespace, filepath in mainScriptPaths:
      currentNamespace = namespace
      let script = readFile(filePath)
      echo "Executing ", filePath
      try:
        evalScriptJs(script)
      except JavaScriptError:
        modError(filePath)
    
    echo "Finished loading mods."
    echo "Unit count: ", allUnits.len
    echo "Unlockable: ", unlockableUnits.len
    writeFile(modDir / "log.txt", modErrorLog)
  else:
    echo "Mod folder does not exist, creating."
    createDir(modDir)

  # Finish credits
  creditsText = &"Your mod folder: {modDir}\n\n" & creditsText
  creditsText &= "\n" & creditsTextEnd