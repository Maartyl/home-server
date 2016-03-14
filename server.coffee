express     = require 'express'
fs          = require 'fs'
bodyParser  = require 'body-parser'
multer      = require 'multer'
log4js      = require 'log4js'
morgan      = require 'morgan'
minimist    = require 'minimist'

packageJson = require './package.json'

argh = minimist process.argv.slice 2 # opts in hash

log4js.loadAppender 'file'
log4js.addAppender (log4js.appenders.file 'logs/home-server.log'), 'h-serv'
logger = log4js.getLogger 'h-serv'
logger.setLevel 'TRACE'
errNonNil = (err) -> logger.error err if err

app = express()

version = packageJson.version
port = argh.port or argh.p or 8880
upload_key = undefined


# asynchronous initializations
init = (cont) ->
  fs.readFile './private/upload_key', (err, data) ->
    if err then return logger.error err

    upload_key = data.toString 'utf8'
    cont {}


upload = multer dest:'./uploads/'

app.use morgan ':remote-addr :remote-user ":method :url HTTP/:http-version"' +
  ' :status :res[content-length] ":referrer" ":user-agent"',
  stream: write: (x) -> logger.trace x # needs lambda to retain logger:this

app.use express.static 'public' #serve static files in 'public' folder
app.use bodyParser.urlencoded extended:true #parse form responses in POST

app.set 'views', './views'
app.set 'view engine', 'jade'

app.enable 'trust proxy'
app.disable 'x-powered-by'  # don't include header 'powered by express'

###
log_req = (req) ->
  logger.trace("connection: #{req.headers['x-forwarded-for'] or '?'}," +
    " #{req.connection.remoteAddress}, #{req.ips} @ #{req.method} #{req.url}")
###

app.get '/wallpaper', (req, res)->
  # log_req req
  res.render 'wallpaper',
    version:version

app.get '/upload', (req, res) ->
  # log_req req
  res.render 'upload',
    title: 'Upload file'
    fFileId: 'toSave'
    action: '/upload'



update_file_map = (id, name) ->
  data = id + ': ' + name + '\n'
  fs.appendFile './uploads/index.cson', data, errNonNil

app.post '/upload', upload.single('toSave'), (req, res) ->
  # log_req req
  key = req.body.key
  file = req.file

  unless file
    return res.render 'error', msg:'No file provided'

  if key isnt upload_key
    fs.unlink file.path, errNonNil
    logger.warn 'wrong key: ' + key
    res.render 'error', msg: 'Wrong key'
  else
    update_file_map file.filename, file.originalname
    logger.info 'file uploaded: ' + file.originalname + ' @ ' + file.path
    res.render 'success', msg:'Uploaded'



# this handles 404
# must be after all routes and everything
app.use (req, res, next) ->
  res.status 404
  res.render 'error', msg:'404'

start_server = (opts) ->
  app.listen port, -> logger.info("server started on #{port};  version: #{version}")

init start_server
