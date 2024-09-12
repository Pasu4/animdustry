# Changelog

## v2.1.0

- Added mod browser
- Added `state.smoothTurn` to API
- Added changelog
- Changed save format to JSON
- Fixed crash when showing the splash image of modded units
- Multiple issues on Android
    - `zip` library does not work, using it causes SIGSEGV on startup (`zippy` does not compile)
    - HTTP client freezes the game
