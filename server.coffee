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


start_repl = (context) ->
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


server = app.listen 3000, () ->
  console.log 'Listening on port %d', server.address().port
