log4js      = require 'log4js'

log_file = 'logs/home-server.log'

log4js.loadAppender 'file'
log4js.addAppender (log4js.appenders.file log_file), 'h-serv'
logger = log4js.getLogger 'h-serv'
logger.setLevel 'TRACE'

module.exports = logger

@errNonNil = (err) -> logger.error err if err
