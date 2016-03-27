express         = require 'express'
lz              = require 'lz-string'
logger          = require 'app/logger'
  
module.exports = (opts) -> (ret) ->
  r = express.Router()
  r.get '/compose', (req, res) ->
    res.render 'multiurl_form',
      action:opts.action + '/compose'

  r.post '/compose', (req, res) ->
    uris = req.body.uris
    unless uris?
      return res.render 'error', msg:'Missing uris: cannot compose.'

    composed = lz.compressToEncodedURIComponent uris.trim()
    res.redirect opts.action + '/' + composed

  r.get '/:uris', (req, res) ->
    composed = req.params.uris
    uris = lz.decompressFromEncodedURIComponent composed

    unless uris
      return res.render 'error', msg:'Invalid uri-list.'

    uri_arr = uris.trim().split '\n'
    res.render 'multiurl',
      uris: uri_arr

  ret null, r
