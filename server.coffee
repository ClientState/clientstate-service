express = require "express"
redis = require "redis"
repl = require "repl"
favicon = require "serve-favicon"



app = express()
app.use favicon "#{__dirname}/public/favicon.ico"
# collect the rawBody
app.use (req, res, next) ->
  data = ''
  req.setEncoding 'utf8'
  req.on 'data', (chunk) ->
    data += chunk
  req.on 'end', () ->
    req.rawBody = data
    next()



db = redis.createClient()


start = (context) ->
  r = repl.start("> ")
  for k,v of context
    r.context[k] = v


GET_COMMANDS = [
  "GET",
  # Lists
  "LRANGE",
]
app.get '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  if c.toUpperCase() not in GET_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      return res.send(dbres)
    else
      res.status(500)
      return res.send(err.toString())

  args = [key]
  if req.query.args?
    args.push.apply args, req.query.args.split ','
  args.push retrn
  db[c].apply db, args


POST_COMMANDS = [
  # Strings
  "APPEND", "SET",
  # Lists
  "LPUSH",
]
app.post '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  v = req.rawBody

  if c.toUpperCase() not in POST_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      return res.send("true")
    else
      res.status(500)
      return res.send(err.toString())

  db[c] key, v, retrn
  # Only supporting single value for LPUSH
  # trying to support multiple values as an option.
  ###
  # string or object is LPUSHed as a string
  # Array LPUSHs each member
  if v instanceof Array
    v = (JSON.stringify(m) for m in v)
    # create args for multiple values eg LPUSH
    # http://stackoverflow.com/a/18094767/177293
    v.unshift key
    v.push retrn
    db[c].apply db, v
  else
    # http://stackoverflow.com/q/203739/177293
    if v.constructor is String
      console.log "STRING", v
      db[c] key, v, retrn
    else
      console.log "NOT STRING", v
      db[c] key, JSON.stringify(v), retrn
  ###


###
logErrors = (err, req, res, next) ->
  console.error err.stack
  next err

app.use logErrors
###

server = app.listen 3000, () ->
  console.log 'Listening on port %d', server.address().port
