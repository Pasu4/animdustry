import os, vars, types, strformat, sequtils, core, fau/assets, tables, msgpack4nim, msgpack4nim/msgpack4collection, std/json, mods

let 
  dataDir = getSaveDir("animdustry")
  dataFileLegacy = dataDir / "data.bin"
  settingsFileLegacy = dataDir / "settings.bin"
  dataFile = dataDir / "data.json"
  settingsFile = dataDir / "settings.json"
var
  jsonSave: JsonNode = newJObject()
  jsonSettings: JsonNode = newJObject()

#region Utils

proc findUnit(name: string): Unit =
  for unit in allUnits:
    if unit.qualifiedName == name:
      return unit
  return unitAlpha

#endregion

#region Legacy

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

# proc saveSettings* =
#   try:
#     dataDir.createDir()
#     settingsFile.writeFile(pack(settings))
#   except:
#     echo &"Error: Failed to write settings: {getCurrentExceptionMsg()}"

proc loadSettingsLegacy* =
  if fileExists(settingsFileLegacy):
    echo "Loading legacy settings from ", settingsFileLegacy
    try:
      unpack(settingsFileLegacy.readFile, settings)
      echo "Loaded legacy settings."
    except: echo &"Failed to load legacy settings: {getCurrentExceptionMsg()}"

# proc saveGame* =
#   try:
#     dataDir.createDir()
#     dataFile.writeFile(pack(save))
#   except:
#     echo &"Error: Failed to write save data: {getCurrentExceptionMsg()}"

proc loadGameLegacy* =
  echo "Loading legacy game state from ", dataFileLegacy
  ## Loads game data from the save file. Does nothing if there is no data.
  if fileExists(dataFileLegacy):
    try:
      unpack(dataFileLegacy.readFile, save)
      echo "Loaded legacy game state."
    except: echo &"Failed to load legacy save state: {getCurrentExceptionMsg()}"

#endregion

#region Mods

proc saveSettings* =
  try:
    jsonSettings["audioLatency"] = % settings.audioLatency
    jsonSettings["globalVolume"] = % settings.globalVolume
    jsonSettings["gamepad"] = % settings.gamepad
    jsonSettings["gamepadLeft"] = % settings.gamepadLeft
    jsonSettings["showFps"] = % settings.showFps

    # For custom settings
    # TODO: implement
    if not jsonSave.hasKey("mods"):
      jsonSettings["mods"] = newJObject()

    dataDir.createDir()
    settingsFile.writeFile(jsonSettings.pretty())
  except:
    echo &"Error: Failed to write settings: {getCurrentExceptionMsg()}"

proc loadSettings* =
  if not fileExists(settingsFile) and fileExists(settingsFileLegacy):
    echo "Loading legacy settings from ", settingsFileLegacy
    loadSettingsLegacy()
    saveSettings()

  elif fileExists(settingsFile):
    try:
      jsonSettings = settingsFile.readFile.parseJson

      settings.audioLatency = jsonSettings["audioLatency"].getFloat()
      settings.globalVolume = jsonSettings["globalVolume"].getFloat()
      settings.gamepad = jsonSettings["gamepad"].getBool()
      settings.gamepadLeft = jsonSettings["gamepadLeft"].getBool()
      settings.showFps = jsonSettings["showFps"].getBool()

      # For custom settings
      mods.customModSettings = jsonSettings["mods"]

      echo "Loaded settings."
    except: echo &"Failed to load settings: {getCurrentExceptionMsg()}"

proc saveGame* =
  try:
    # Data is added, not overwritten
    # This is to prevent data loss when uninstalling or reinstalling mods

    jsonSave["introDone"] = % save.introDone
    jsonSave["copper"] = % save.copper
    jsonSave["rolls"] = % save.rolls
    jsonSave["lastUnit"] = if save.lastUnit != nil: % save.lastUnit.qualifiedName else: % unitAlpha.qualifiedName

    if not jsonSave.hasKey("units"):
      jsonSave["units"] = newJObject()
    if not jsonSave.hasKey("scores"):
      jsonSave["scores"] = newJObject()

    for unit in save.units:
      if jsonSave["units"].hasKey(unit.qualifiedName):
        jsonSave["units"][unit.qualifiedName]["duplicates"] = % save.duplicates.getOrDefault(unit.qualifiedName, 0)
      else:
        jsonSave["units"][unit.qualifiedName] = %* {
          "duplicates": save.duplicates.getOrDefault(unit.qualifiedName, 0)
        }

    for i, map in allMaps.pairs:
      jsonSave["scores"][map.qualifiedName] = if save.scores.len > i: % save.scores[i] else: % 0

    dataDir.createDir()
    dataFile.writeFile(jsonSave.pretty())
  except:
    echo &"Error: Failed to write save data: {getCurrentExceptionMsg()}"

proc loadGame* =
  ## Loads game data from the save file. Does nothing if there is no data.
  if not fileExists(dataFile) and fileExists(dataFileLegacy):
    echo "Loading legacy save data from ", dataFileLegacy
    loadGameLegacy()
    saveGame()
  elif fileExists(dataFile):
    try:
      echo "Loading game from ", dataFile
      
      jsonSave = dataFile.readFile.parseJson

      save.introDone = jsonSave["introDone"].getBool()
      save.copper = jsonSave["copper"].getInt()
      save.rolls = jsonSave["rolls"].getInt()
      save.lastUnit = findUnit(jsonSave["lastUnit"].getStr())

      save.units = @[]
      for key, value in jsonSave["units"].getFields:
        save.units.add(findUnit(key))
        save.duplicates[key] = value["duplicates"].getInt()

      if save.scores.len < allMaps.len:
        save.scores.setLen(allMaps.len)

      for i, map in allMaps.pairs:
        save.scores[i] = jsonSave["scores"]{map.qualifiedName}.getInt(0)

      echo "Loaded game state."
    except: echo &"Failed to load save state: {getCurrentExceptionMsg()}"
  else:
    echo "No save data found."

#endregion
