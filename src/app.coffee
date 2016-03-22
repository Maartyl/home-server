express     = require 'express'
minimist    = require 'minimist'
async = require 'async'

# middleware
morgan      = require 'morgan'
compression = require 'compression'
bodyParser  = require 'body-parser'
sass        = require 'node-sass-middleware'

# app/ refers to root dir; symlink in node_modules
# extend      = require 'app/extend'
logger      = require 'app/logger'

# cont:: (err, app) -> ()
@with_app = (parameters, cont) ->
  app = express()
  app.locals.parameters = parameters
  app.set 'views', './views'
  app.set 'view engine', 'jade'
# app.enable 'trust proxy'
  app.disable 'x-powered-by'  # don't include header 'powered by express'

  extend_route app, [                                           # MIDDLEWARE
      compression()
      express.static 'public' #serve static files in 'public' folder
      sass # CSS template engine (like LESS but better)
        src: 'client/scss'
        dest: 'public/css' # where save, if generated files
        response: true # render directly to response
        outputStyle: 'compressed'
        debug: parameters.debugSass
        prefix: '/css' # where 'outside' looks
        error: logger.error
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
      unless err
        # this handles 404
        # must be after all routes and everything
        app.use (req, res, next) -> res.status(404).render '404'
#TODO: add error handling
      cont err, app


# app(route), [use use use], {'/path': ((err, Router -> ()) -> ())}, cont::(err, app)
@extend_route = extend_route = (app, middlewares, routes, cont) ->
  app.use.apply app, middlewares
  async.parallel routes,
    (err, routes) ->
      unless err
        for path, r of routes
          app.use path, r
      cont err, app

