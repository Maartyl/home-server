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

packageJson = require './package.json'

argh = minimist process.argv.slice 2 # opts in hash

myUri = 'https://maa.home.kg/' # must match HTTPS certificate

log4js.loadAppender 'file'
log4js.addAppender (log4js.appenders.file 'logs/home-server.log'), 'h-serv'
logger = log4js.getLogger 'h-serv'
logger.setLevel 'TRACE'
errNonNil = (err) -> logger.error err if err

version = packageJson.version
upload_key = undefined

app = express()
start_server = (opts) ->
  http_redirect_serv().listen opts.httpPort, ->
    logger.info "HTTP redirect server started on #{opts.httpPort};  version: #{version}"
  (require 'https').createServer(opts.credentials, app).listen opts.httpsPort, ->
    logger.info "HTTPS server started on #{opts.httpsPort};  version: #{version}"

http_redirect_serv = ->
  express().use (req, res, next) ->
    res.redirect 301, myUri

readFileCurry = (path) ->
  (cont) -> fs.readFile path, 'utf8', cont

# dynamic initializations
init = (cont) ->
  loadSSL = (suff) -> readFileCurry 'sslcert/server.' + suff

  async.parallel
    up_key: readFileCurry './private/upload_key'
    c_key: loadSSL 'key'
    c_cert: loadSSL 'cert'
    c_ca: loadSSL 'intermediate.pem'
    (err, rets) ->
      if err then return logger.error err

      upload_key = rets.up_key.toString('utf8').trim()
      cont
        httpPort: argh.port or argh.p or 8880
        httpsPort: argh.sslPort or argh.s or 4443
        credentials:
          key: rets.c_key
          cert: rets.c_cert
          ca: rets.c_ca

# MIDDLEWARE & settings

upload = multer dest:'./uploads/' # middleware, but only used for specific routes

app.use compression()
app.use express.static 'public' #serve static files in 'public' folder
app.use morgan ':remote-addr :remote-user ":method :url HTTP/:http-version"' +
  ' :status :res[content-length] ":referrer" ":user-agent"',
  stream: write: (x) -> logger.trace x # needs lambda to retain logger:this
app.use bodyParser.urlencoded extended:true #parse form responses in POST

app.set 'views', './views'
app.set 'view engine', 'jade'
# app.enable 'trust proxy'
app.disable 'x-powered-by'  # don't include header 'powered by express'

# ROUTES

app.get '/wallpaper', (req, res)->
  res.render 'wallpaper',
    version:version

app.get '/upload', (req, res) ->
  res.render 'upload',
    title: 'Upload file'
    fFileId: 'toSave'
    action: '/upload'

app.post '/upload', upload.single('toSave'), (req, res) ->
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

app.get '/ignore', ->
  zxczxczxczc = 5

# SSL thing: proof of ownership
app.get '/.well-known/acme-challenge/qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M', (req, res)->
  res.send 'qGBfw4Z1_XIXHi2Njl5n2WThOnIrXXBqrHm0N76GC1M.fNQWXQOTMH1J_ZevkEw32KXBSCotohqXqazp68pkv2Q'



# this handles 404
# must be after all routes and everything
app.use (req, res, next) ->
  res.status 404
    .render '404'


#
# other functions
#
update_file_map = (id, info) ->
  data = cson.createCSONString "#{id}": info
  fs.appendFile './uploads/index.cson', data + '\n', errNonNil


# all static set up: start server
init start_server
