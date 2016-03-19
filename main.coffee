require 'coffee-script/register' # allows requiring .coffee modules

express     = require 'express'
bodyParser  = require 'body-parser'
morgan      = require 'morgan'
minimist    = require 'minimist'
compression = require 'compression'
async       = require 'async'

# app/ refers to root dir; symlink in node_modules
extend      = require 'app/extend'
logger      = require 'app/logger'
server      = require 'app/server'

packageJson = require 'app/package.json'

argh = minimist process.argv.slice 2 # opts in hash

parameters =
  server_uri: 'https://maa.home.kg' # must match HTTPS certificate
  port_http: argh.port or argh.p or 8880
  port_https: argh.sslPort or argh.s or 4443
  server_version: packageJson.version

app = express()
app.locals.parameters = parameters
app.set 'views', './views'
app.set 'view engine', 'jade'
# app.enable 'trust proxy'
app.disable 'x-powered-by'  # don't include header 'powered by express'

extend.route app, [                                     # MIDDLEWARE
    compression()
    express.static 'public' #serve static files in 'public' folder
    morgan ':remote-addr :remote-user ":method :url HTTP/:http-version"' +
      ' :status :res[content-length] ":referrer" ":user-agent"',
      stream: write: (x) -> logger.trace x # needs lambda to retain logger:this
    bodyParser.urlencoded extended:true #parse form responses in POST
  ],                                                    # ROUTES
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
    server.init app


# SSL thing: proof of ownership
app.get '/.well-known/acme-challenge/qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M', (req, res)->
  res.send 'qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M.fNQWXQOTMH1J_ZevkEw32KXBSCotohqXqazp68pkv2Q'

