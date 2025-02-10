import os, strformat, core, fau/assets, fau/globals, std/[json, strutils, sequtils, tables, httpclient, base64, uri, asyncdispatch, asyncfile]
import vars, types, jsonapi, jsapi, apivars, patterns, hjson, semver

when not isMobile:
  import zippy/ziparchives
# else:
#   import zip/zipfiles

type InstalledMod* = object
  namespace*: string
  version*: SemVer
  enabled*: bool
  isRepo*: bool # Whether the mod contains a git repository

type RemoteMod* = object
  name*: string
  namespace*: string
  author*: string
  description*: string
  version*: SemVer
  tags*: seq[string]
  debug*: bool
  repoName*: string
  repoOwner*: string
  repoUrl*: string
  downloadUrl*: string
  creationDate*: string
  lastUpdate*: string

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
  installedModList*: seq[InstalledMod]
  remoteModList*: seq[RemoteMod]
  modListLoaded* = false
  modListLastUpdated*: string
  activeDownload*: Future[void] = asyncdispatch.all[void]() # Initialized as completed
  downloadProgressString*: string = ""
  downloadFailed*: bool = false
  downloadErrorString*: string = ""
  restartRequired* = false
  customModSettings*: JsonNode

template modError(filePath) =
  modErrorLog &= &"In {filePath[modDir.len..^1]}:\n{getCurrentExceptionMsg()}\n"
  mode = gmModError
  continue

proc loadModList* =
  if modListLoaded:
    return
  modListLoaded = true

  # Fetch mods from their repositories
  var client = newHttpClient()
  try:
    echo "Fetching mod list"
    modList = parseJson(client.getContent("https://raw.githubusercontent.com/Pasu4/animdustry-mods/master/mod-list.json"))
    echo "Mod list fetched"

    modListLastUpdated = modList["updated"].getStr()

    # Convert to mod list
    for m in modList["mods"].getElems():
      remoteModList.add(RemoteMod(
        name:         m["name"].getStr(),
        namespace:    m["namespace"].getStr(),
        author:       m["author"].getStr(),
        description:  m["description"].getStr(),
        version:      m["version"].getStr().newSemVer("0.0.0"),
        tags:         m["tags"].getElems().map(proc(j: JsonNode): string = j.getStr()),
        debug:        m["debug"].getBool(),
        repoName:     m["repoName"].getStr(),
        repoOwner:    m["repoOwner"].getStr(),
        repoUrl:      m["repoUrl"].getStr(),
        downloadUrl:  m["downloadUrl"].getStr(),
        creationDate: m["creationDate"].getStr(),
        lastUpdate:   m["lastUpdate"].getStr(),
      ))
  finally:
    client.close()

proc qualifiedName*(unit: Unit): string =
  if not unit.isModded:
    return unit.name
  return unit.modNamespace & "::" & unit.name

proc qualifiedName*(map: Beatmap): string =
  if not map.isModded:
    return map.name
  return map.modNamespace & "::" & map.name

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
            isRepo = dirExists(modPath / ".git")
          
          modName = modNode["name"].getStr()
          modAuthor = modNode["author"].getStr()
          currentNamespace = modNode["namespace"].getStr()
          modLegacy = modNode{"legacy"}.getBool(false) # Legacy mods use JSON scripts instead of JavaScript

          modPaths[currentNamespace] = modPath

          installedModList.add(InstalledMod(
            namespace: currentNamespace,
            version: modNode["version"].getStr().newSemVer("0.0.0"),
            enabled: modEnabled,
            isRepo: isRepo
          ))

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
                    modPath: modPath,
                    modNamespace: currentNamespace
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
                    name: mapNode["name"].getStr(),
                    songName: songName,
                    music: mapNode["music"].getStr(),
                    bpm: mapNode["bpm"].getFloat(),
                    beatOffset: mapNode["beatOffset"].getFloat(),
                    maxHits: mapNode["maxHits"].getInt(),
                    copperAmount: mapNode["copperAmount"].getInt(),
                    fadeColor: parseColor(mapNode["fadeColor"].getStr()), # Fau color

                    isModded: true,
                    modPath: modPath,
                    modNamespace: currentNamespace,
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

proc downloadMod*(m: RemoteMod) {.async.} =
  try:
    echo "Starting download of ", m.name

    downloadFailed = false
    restartRequired = true

    let tempPath = dataDir / "temp"

    # Async does not work on Android
    when not isMobile:
      downloadProgressString = "Downloading mod..."
      await sleepAsync(0) # Allow UI to update

    # Create empty temp directory
    if dirExists(tempPath):
      removeDir(tempPath)
    createDir(tempPath)

    # Zippy and async don't work on Android
    when not isMobile:
      echo "Downloading from ", m.downloadUrl
      
      # Download zip file
      let client = newAsyncHttpClient()
      var content: string
      try:
        let response = await client.get(m.downloadUrl)
        content = await response.body
      finally:
        client.close()
      
      echo "Writing to ", tempPath / "temp.zip"
      downloadProgressString = "Writing to temporary file..."
      await sleepAsync(0)

      var tempFile: AsyncFile
      # writeFile(tempPath / "temp.zip", content)
      try:
        tempFile = openAsync(tempPath / "temp.zip", fmWrite)
        await tempFile.write(content)
      except:
        downloadFailed = true
        echo "Error writing file: ", getCurrentExceptionMsg()
        downloadErrorString = getCurrentExceptionMsg()
        return # Will still execute finally block
      finally:
        tempFile.close()

      # Extract file
      echo "Extracting..."
      downloadProgressString = "Extracting mod..."
      await sleepAsync(0)
      extractAll(tempPath / "temp.zip", tempPath / "extracted")
        
    # else: # isMobile

    #   echo "Downloading from ", m.downloadUrl

    #   # Download zip file
    #   let client = newHttpClient()
    #   var content: string
    #   try:
    #     let response = client.get(m.downloadUrl)
    #     content = response.body
    #   finally:
    #     client.close()
    #   echo "Writing to ", tempPath / "temp.zip"

    #   writeFile(tempPath / "temp.zip", content)

    #   # Extract file
    #   echo "Extracting..."
    #   var archive: ZipArchive
    #   if not archive.open(tempPath / "temp.zip"):
    #     downloadErrorString = "Error opening zip file"
    #   archive.extractAll(tempPath / "extracted")

    # `when` block ends here

    # Delete old mod folder if it exists
    if dirExists(modDir / m.namespace):
      echo "Deleting old mod folder..."
      when not isMobile:
        downloadProgressString = "Deleting old mod folder..."
        await sleepAsync(0)
      removeDir(modDir / m.namespace)
    
    # Move extracted file to mod folder
    for kind, path in walkDir(tempPath / "extracted"):
      echo "Moving downloaded mod to ", modDir / m.namespace, "..."
      when not isMobile:
        downloadProgressString = "Moving mod to mod folder..."
        await sleepAsync(0)
      moveDir(path, modDir / m.namespace) # The extracted file's name does not matter
      break # Only one directory is expected

    # Delete temp folder
    echo "Deleting temp folder..."
    when not isMobile:
      downloadProgressString = "Cleaning up..."
      await sleepAsync(0)
    removeDir(tempPath)

    # Update installed mod list
    echo "Updating installed mod list..."
    when not isMobile:
      downloadProgressString = "Updating installed mod list..."
      await sleepAsync(0)

    var found = false
    for i in 0..installedModList.high:
      if installedModList[i].namespace == m.namespace:
        installedModList[i].version = m.version
        found = true
        break
    if not found:
      installedModList.add(InstalledMod(
        namespace: m.namespace,
        version: m.version,
        enabled: true
      ))

    echo "Download finished."

  except:
    downloadFailed = true
    echo "Error downloading mod: ", getCurrentExceptionMsg()
    downloadErrorString = getCurrentExceptionMsg()
