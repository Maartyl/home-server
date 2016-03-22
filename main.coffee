require 'coffee-script/register' # allows requiring .coffee modules

minimist    = require 'minimist'

# app/ refers to root dir; symlink in node_modules
logger      = require 'app/logger'
server      = require 'app/server'
{with_app}  = require 'app/app'

packageJson = require './package.json'

argh = minimist process.argv.slice 2 # opts in hash

with_app
  server_uri: 'https://maa.home.kg' # must match HTTPS certificate
  port_http: argh.port or argh.p or 8880
  port_https: argh.sslPort or argh.s or 4443
  server_version: packageJson.version
  debug: false
  debugSass: false
  (err, app) ->
    if err then return logger.error err
    server.init app

