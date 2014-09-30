express = require "express"
redis = require "redis"
repl = require "repl"
favicon = require "serve-favicon"


app = express()
app.use favicon "#{__dirname}/public/favicon.ico"

db = redis.createClient()


start = (context) ->
  r = repl.start("> ")
  for k,v of context
    r.context[k] = v



GET_COMMANDS = [
  "GET",
]
app.get '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  if c.toUpperCase() not in GET_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()
  db[c] key, (err, dbres) ->
    res.send dbres


POST_COMMANDS = [
  "SET",
]
app.post '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  v = req.query["v"]
  if c.toUpperCase() not in POST_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()
  db[c] key, v, (err, dbres) ->
    if not err
      return res.send("true")
    else
      res.status(500)
      return res.send(err.toString())


###
logErrors = (err, req, res, next) ->
  console.error err.stack
  next err

app.use logErrors
###

server = app.listen 3000, () ->
  console.log 'Listening on port %d', server.address().port
