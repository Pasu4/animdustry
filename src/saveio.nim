import os, vars, types, strformat, core, fau/assets, tables, msgpack4nim, msgpack4nim/msgpack4collection

let 
  dataDir = getSaveDir("animdustry")
  dataFile = dataDir / "data_mod.bin"
  dataFileUnmod = dataDir / "data.bin"
  #TODO
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
  let file = (if fileExists(dataFile): dataFile else: dataFileUnmod) # Load unmodded file 
  echo "Loading game from ", file
  ## Loads game data from the save file. Does nothing if there is no data.
  if fileExists(file):
    try:
      unpack(file.readFile, save)
      echo "Loaded game state."
    except: echo &"Failed to load save state: {getCurrentExceptionMsg()}"
