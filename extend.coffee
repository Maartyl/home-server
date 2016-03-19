async = require 'async'

# app(route), [use use use], {'/path': ((err, Router -> ()) -> ())}, cont::(err, app)
@route = (app, middlewares, routes, cont) ->
  app.use.apply app, middlewares
  async.parallel routes,
    (err, routes) ->
      unless err
        for path, r of routes
          app.use path, r
      cont err, app

