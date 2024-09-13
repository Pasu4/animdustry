#!/bin/bash

nimble deploy win
nimble deploy lin
nimble androidPackage
cp android/build/outputs/apk/debug/android-debug.apk ./build/
cp doc/api.js ./build/__api.js
printf '\x07' # ring bell
