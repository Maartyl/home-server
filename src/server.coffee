express     = require 'express'
async       = require 'async'

util        = require 'app/util'
logger      = require 'app/logger'


start_server = (opts) ->
  http_redirect_serv(opts.uri).listen opts.httpPort, ->
    logger.info "HTTP redirect server started on #{opts.httpPort};  version: #{opts.version}"
  (require 'https').createServer(opts.credentials, opts.app).listen opts.httpsPort, ->
    logger.info "HTTPS server started on #{opts.httpsPort};  version: #{opts.version}"

http_redirect_serv = (uri) ->
  express().use (req, res, next) ->
    res.redirect 301, uri + req.url

loadSSL = (suff) -> util.readFileCurry 'sslcert/server.' + suff

# dynamic initializations
# initializes and starts server
@init = (app) ->
  async.parallel
    key: loadSSL 'key'
    cert: loadSSL 'cert'
    ca: loadSSL 'intermediate.pem'
    (err, creds) ->
      if err then return logger.error err

      start_server
        app: app
        uri: app.locals.parameters.server_uri
        version: app.locals.parameters.server_version
        httpPort: app.locals.parameters.port_http
        httpsPort: app.locals.parameters.port_https
        credentials: creds

