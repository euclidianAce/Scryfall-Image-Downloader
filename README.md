# What is this?
A scryfall image downloader I made to practice working with LuaSec, web apis, and Lua's coroutines.
Not really meant for actual use, but could be convenient for something.

# Dependencies
Needs LuaSec and the cjson libraries, which are on luarocks
```
$ luarocks install luasec
$ luarocks install lua-cjson
```

# Usage
Should be compatible with Lua 5.1-5.3 and LuaJIT.
To use just run it from a command line with search terms as arguments
```
$ lua scryfallImageDownload.lua "once upon a time" "sliver queen"
```

Or make the file executable
```
$ chmod +x scryfallImageDownload.lua
$ ./scryfallImageDownload.lua "gilded goose" "gideon blackblade" "food chain"
```

