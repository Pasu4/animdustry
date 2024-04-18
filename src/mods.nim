import os, vars, types, strformat, core, fau/assets, std/[json, strutils, sequtils, tables, httpclient, base64, uri]
import jsonapi, patterns, hjson

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
  modList*: seq[ModListEntry]
  modListLoaded* = false

template modError =
  modErrorLog &= &"In {filePath[modDir.len..^1]}:\n{getCurrentExceptionMsg()}\n"
  mode = gmModError
  continue

# Downloads a json file from the latest release of the repository.
# If there is no latest release, downloads from head.
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
    let modListJson = client.downloadJsonFromGithub("https://github.com/Pasu4/animdustry", "mod-list.json", "HEAD")
    for m in modListJson["mods"].getElems():
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
  finally:
    client.close()

proc loadMods* =
  # Load local mods
  echo "Loading mods from ", modDir
  if dirExists(modDir):
    for kind, modPath in walkDir(modDir):
      echo &"Found {kind} {modPath}"
      let isHjson = fileExists(modPath / "mod.hjson")
      if kind == pcDir and isHjson or fileExists(modPath / "mod.json"):
        var modName, modAuthor: string
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

          if not modEnabled: continue
          debugMode = modDebug
          
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
        
        echo &"Loading {modName} by {modAuthor}"

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

                parsedUnit.draw = getUnitDraw(unitNode["draw"])
                parsedUnit.abilityProc = getUnitAbility(unitNode["abilityProc"])

                allUnits.add(parsedUnit)
                unlockableUnits.add(parsedUnit)
              except JsonParsingError, HjsonParsingError, KeyError:
                modError()
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
              except JsonParsingError, HjsonParsingError, KeyError:
                modError()
              #endregion
        # Procedures
        if dirExists(procedurePath):
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
                modError()
              #endregion
          # Call Init procedure
          if (currentNamespace & "::Init") in procedures:
            procedures[currentNamespace & "::Init"].script()
        # Credits
        if fileExists(modPath / "credits.txt"):
          creditsText &= "\n" & readFile(modPath / "credits.txt") & "\n\n------\n"
        else:
          # Auto-generate credits
          creditsText &= &"\n- {modName} -\n\nMade by: {modAuthor}\n\n(Auto-generated credits)\n\n------\n"

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