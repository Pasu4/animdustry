version       = "0.0.1"
author        = "Anuken"
description   = "Animdustry"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["main"]
binDir        = "build"

requires("nim >= 2.0.0")
requires("https://github.com/Anuken/fau#" & staticExec("git -C fau rev-parse HEAD").replace("\n", "").replace("\r", ""))
requires("msgpack4nim == 0.4.4")
requires("mathexpr >= 1.3.2")
requires("https://github.com/Pasu4/hjson-nim >= 1.0.3")
# Dependencies for duktape-nim
requires("nimgen")
requires("c2nim")
# requires("duktape >= 0.1.0")
# Above library is not working, so using a fork
requires("https://github.com/Pasu4/duktape-nim#3799e2bab29a120acbc1bc8008354dc52da6388a")

import strformat, os, json, sequtils

template shell(args: string) =
  try: exec(args)
  except OSError: quit(1)

const
  app = "main"
  
  builds = [
    (name: "linux64", os: "linux", cpu: "amd64", args: ""),
    (name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-g++"),
    (name: "mac64", os: "macosx", cpu: "amd64", args: "")
  ]

task pack, "Pack textures":
  shell &"faupack -p:\"{getCurrentDir()}/assets-raw/sprites\" -o:\"{getCurrentDir()}/assets/atlas\""

task debug, "Run the game in debug mode - for development only!":
  packTask()
  shell &"nim r -d:debug -d:ssl src/{app}"

task run, "Run the game":
  packTask()
  shell &"nim r -d:release -d:ssl src/{app}"

task debugBin, "Create debug build file":
  shell &"nim c -d:debug -d:ssl -o:{app} --debugger:native src/{app}"

task release, "Release build":
  packTask()
  shell &"nim r -d:danger -d:ssl -o:build/{app} src/{app}"

task web, "Deploy web build":
  mkDir "build/web"
  shell &"nim c -f -d:emscripten -d:danger -d:ssl src/{app}.nim"
  writeFile("build/web/index.html", readFile("build/web/index.html").replace("$title$", capitalizeAscii(app)))

task deploy, "Build for all platforms":
  packTask()

  for name, os, cpu, args in builds.items:
    if commandLineParams()[^1] != "deploy" and not name.startsWith(commandLineParams()[^1]):
      continue
    
    if (os == "macosx") != defined(macosx):
      continue

    let
      exeName = &"{app}-{name}"
      dir = "build"
      exeExt = if os == "windows": ".exe" else: ""
      bin = dir / exeName & exeExt

    mkDir dir
    shell &"nim --cpu:{cpu} --os:{os} --app:gui -f {args} -d:danger -d:ssl -o:{bin} c src/{app}"
    if not defined(macosx):
      shell &"strip -s {bin}"

  #webTask()
  #cd "build"
  #shell &"zip -9r {app}-web.zip web/*"

task androidBuild, "Android build":
  var cmakeText = "android/CMakeLists.txt".readFile()

  mkDir "android/src"
  cpFile("android/CMakeLists.txt", "android/src/CMakeLists.txt")

  for arch in ["32", "64"]:
    if dirExists(&"android/src/c{arch}"):
      rmDir &"android/src/c{arch}"
    let cpu = if arch == "32": "" else: "64"

    shell &"nim c -f --compileOnly --cpu:arm{cpu} --os:android -d:danger -c --noMain:on --nimcache:android/src/c{arch} src/{app}.nim"
    var 
      includes: seq[string]
      sources: seq[string]

    let compData = parseJson(readFile(&"android/src/c{arch}/{app}.json"))
    let compList = compData["compile"]
    for arr in compList.items:
      sources.add($arr[0])
    
    #scrape includes from C arguments
    if compList.len > 0:
      let firstCommand = compList[0][1]
      let split = ($firstCommand).split(" ").filterIt(it.startsWith("-I")).mapIt(it[2..^1]).mapIt(if it.startsWith("'"): it[1..^2] else: it)
      includes.add split

    cmakeText = cmakeText
    .replace("${NIM_SOURCES_" & arch & "}", sources.join("\n"))
    .replace("${NIM_INCLUDE_DIR}", includes.mapIt("\"" & it & "\"").join("\n"))

  writeFile("android/src/CMakeLists.txt", cmakeText)

task android, "Android Run":
  androidBuildTask()
  cd "android"
  shell "./gradlew run"

task androidPackage, "Create Android APK (Debug)":
  androidBuildTask()
  cd "android"
  shell "./gradlew assembleDebug"

task androidRelease, "Create Android APK (Release)":
  androidBuildTask()
  cd "android"
  shell "./gradlew assembleRelease"
