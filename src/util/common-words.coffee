readline  = require 'readline'
https     = require 'https'
_         = require 'underscore'
async     = require 'async'

@with_words = (cont) -> words cont

w_url = 'https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt'

# time until words are deleted
w_forget_delay = 1 * 60 * 60 * 1000 # 1 hour in ms

# mut
w_last_accessed_time = new Date 0 #dflt: so long ago it doesn't matter

restoration = ->
  passed = new Date - w_last_accessed_time
  if passed < w_forget_delay
    _.delay restoration, 500 + w_forget_delay - passed
  else words = words_restore()

# function to return words
# :: (ret:: (err, words) -> ()) -> ()
words_ = (ret) ->
  do (ret = _.once ret; words = []) ->
    ret_err = (err, words) ->
      ret err, words
      # wait shorter time before retrying if error
      _.delay restoration, w_forget_delay/30
      w_last_accessed_time = new Date 0 # not accessed <- error
    https.get w_url, (res) ->
      unless 200 <= res.statusCode < 300
        return ret new Error 'words.get: non-OK status: ' + res.statusCode

      readline.createInterface # provides 'line' event
        input: res
        terminal: false
      .on 'line', words.push.bind words
      .on 'close', ->
        ret null, words
        _.delay restoration, w_forget_delay
      .on 'error', ret_err
    .on 'error', ret_err

# initializes words and forgets the array if not needed for long enough
# stores reference to words for w_forget_delay
words_restore = ->
  _.compose \
    -> w_last_accessed_time = new Date
    async.memoize(words_, -> 0) # like _.once, but async; has no args: always same

# mut: only words_restore()
# words array can be used in callback
words = words_restore()

