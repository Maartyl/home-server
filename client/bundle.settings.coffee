def = (getter) ->
  get: getter
  enumerable: true

# load lazily //by using getters
Object.defineProperties module.exports,
  Templates:def -> require './gen/templates'
  IO:def -> require 'socket.io-client'
