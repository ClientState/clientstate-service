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


app.get '/:command', (req, res) ->
  c = req.param "command"
  start
    db: db
    req: req
    res: res
    c: c
  res.send "OK"


###
logErrors = (err, req, res, next) ->
  console.error err.stack
  next err

app.use logErrors
###

server = app.listen 3000, () ->
  console.log 'Listening on port %d', server.address().port
