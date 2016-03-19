require 'coffee-script/register' # allows requiring .coffee modules

express     = require 'express'
fs          = require 'fs'
bodyParser  = require 'body-parser'
multer      = require 'multer'
log4js      = require 'log4js'
morgan      = require 'morgan'
minimist    = require 'minimist'
compression = require 'compression'
cson        = require 'cson'
async       = require 'async'
_           = require 'underscore'

extend      = require './extend'
util        = require './util'

packageJson = require './package.json'

argh = minimist process.argv.slice 2 # opts in hash

myUri = 'https://maa.home.kg' # must match HTTPS certificate

log4js.loadAppender 'file'
log4js.addAppender (log4js.appenders.file 'logs/home-server.log'), 'h-serv'
logger = log4js.getLogger 'h-serv'
logger.setLevel 'TRACE'
errNonNil = (err) -> logger.error err if err

version = packageJson.version

app = express()
start_server = (opts) ->
  http_redirect_serv(myUri).listen opts.httpPort, ->
    logger.info "HTTP redirect server started on #{opts.httpPort};  version: #{version}"
  (require 'https').createServer(opts.credentials, app).listen opts.httpsPort, ->
    logger.info "HTTPS server started on #{opts.httpsPort};  version: #{version}"

http_redirect_serv = (uri) ->
  express().use (req, res, next) ->
    res.redirect 301, uri + req.url

# dynamic initializations
init = (cont) ->
  loadSSL = (suff) -> util.readFileCurry 'sslcert/server.' + suff

  async.parallel
    key: loadSSL 'key'
    cert: loadSSL 'cert'
    ca: loadSSL 'intermediate.pem'
    (err, creds) ->
      if err then return logger.error err

      cont
        httpPort: argh.port or argh.p or 8880
        httpsPort: argh.sslPort or argh.s or 4443
        credentials: creds

# SETTINGS

app.set 'views', './views'
app.set 'view engine', 'jade'
# app.enable 'trust proxy'
app.disable 'x-powered-by'  # don't include header 'powered by express'

# ROUTES

c_wallpaper = (ret) ->
  ret null, express.Router().get '/', (req, res)->
    res.render 'wallpaper',
      version:version

c_uploader = (opts) -> (ret) ->
  update_file_map = (id, info) ->
    data = cson.createCSONString "#{id}": info
    fs.appendFile opts.uploads + '/index.cson', data + '\n', errNonNil

  fs.readFile opts.key_path, 'utf8', (err, data)->
    if err then return ret err, null

    upload_key = data.toString('utf8').trim()
    upload = multer dest:opts.uploads

    form_file_name = 'toSave'

    r = express.Router()
    r.get '/', (req, res) ->
      res.render 'upload',
        title: 'Upload file'
        fFileId:form_file_name
        action: opts.action

    r.post '/', upload.single(form_file_name), (req, res) ->
      key = req.body.key?.trim()
      file = req.file

      unless file
        return res.render 'error', msg:'No file provided'

      if key isnt upload_key
        fs.unlink file.path, errNonNil
        logger.warn 'wrong key: ' + key
        res.render 'error', msg:'Wrong key'
      else
        update_file_map file.filename, name:file.originalname, src:req.ip
        logger.info 'file uploaded: ' + file.originalname + ' @ ' + file.path
        res.render 'success', msg:'Uploaded'
    ret null, r

extend.route app, [ # MIDDLEWARE
    compression()
    express.static 'public' #serve static files in 'public' folder
    morgan ':remote-addr :remote-user ":method :url HTTP/:http-version"' +
      ' :status :res[content-length] ":referrer" ":user-agent"',
      stream: write: (x) -> logger.trace x # needs lambda to retain logger:this
    bodyParser.urlencoded extended:true #parse form responses in POST
  ], # ROUTES
  '/wallpaper': c_wallpaper
  '/upload': c_uploader
    action:'/upload'
    uploads:'./uploads'
    key_path:'./private/upload_key'
  (err, app) ->
    if err then return logger.error err
    # this handles 404
    # must be after all routes and everything
    app.use (req, res, next) -> res.status(404).render '404'
    init start_server


# SSL thing: proof of ownership
app.get '/.well-known/acme-challenge/qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M', (req, res)->
  res.send 'qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M.fNQWXQOTMH1J_ZevkEw32KXBSCotohqXqazp68pkv2Q'

