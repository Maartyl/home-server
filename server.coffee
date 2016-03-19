require 'coffee-script/register' # allows requiring .coffee modules

express     = require 'express'
bodyParser  = require 'body-parser'
morgan      = require 'morgan'
minimist    = require 'minimist'
compression = require 'compression'
async       = require 'async'

# app/ refers to root dir; symlink in node_modules
extend      = require 'app/extend'
util        = require 'app/util'
logger      = require 'app/logger'

packageJson = require 'app/package.json'

version = packageJson.version
myUri = 'https://maa.home.kg' # must match HTTPS certificate

argh = minimist process.argv.slice 2 # opts in hash

start_server = (opts) ->
  http_redirect_serv(opts.uri).listen opts.httpPort, ->
    logger.info "HTTP redirect server started on #{opts.httpPort};  version: #{version}"
  (require 'https').createServer(opts.credentials, opts.app).listen opts.httpsPort, ->
    logger.info "HTTPS server started on #{opts.httpsPort};  version: #{version}"

http_redirect_serv = (uri) ->
  express().use (req, res, next) ->
    res.redirect 301, uri + req.url

# dynamic initializations
init = (app, server_uri) ->
  loadSSL = (suff) -> util.readFileCurry 'sslcert/server.' + suff

  async.parallel
    key: loadSSL 'key'
    cert: loadSSL 'cert'
    ca: loadSSL 'intermediate.pem'
    (err, creds) ->
      if err then return logger.error err

      start_server
        app: app
        uri: server_uri
        httpPort: argh.port or argh.p or 8880
        httpsPort: argh.sslPort or argh.s or 4443
        credentials: creds

app = express()

# SETTINGS
app.set 'views', './views'
app.set 'view engine', 'jade'
# app.enable 'trust proxy'
app.disable 'x-powered-by'  # don't include header 'powered by express'


extend.route app, [ # MIDDLEWARE
    compression()
    express.static 'public' #serve static files in 'public' folder
    morgan ':remote-addr :remote-user ":method :url HTTP/:http-version"' +
      ' :status :res[content-length] ":referrer" ":user-agent"',
      stream: write: (x) -> logger.trace x # needs lambda to retain logger:this
    bodyParser.urlencoded extended:true #parse form responses in POST
  ], # ROUTES
  '/wallpaper': require 'app/controllers/wallpaper'
  '/upload': require('app/controllers/uploader')
    action:'/upload'
    uploads:'./uploads'
    key_path:'./private/upload_key'
  (err, app) ->
    if err then return logger.error err
    # this handles 404
    # must be after all routes and everything
    app.use (req, res, next) -> res.status(404).render '404'
    init app, start_server


# SSL thing: proof of ownership
app.get '/.well-known/acme-challenge/qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M', (req, res)->
  res.send 'qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M.fNQWXQOTMH1J_ZevkEw32KXBSCotohqXqazp68pkv2Q'

