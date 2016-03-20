express     = require 'express'

module.exports = (ret) ->
  ret null, express.Router().get '/', (req, res) ->
    res.render 'wallpaper'

