fs          = require 'fs'

@readFileCurry = (path) ->
  (cont) -> fs.readFile path, 'utf8', cont
