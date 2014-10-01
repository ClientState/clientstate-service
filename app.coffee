express = require "express"
repl = require "repl"
favicon = require "serve-favicon"

# node_redis client
db = require("./db").db
start_repl = require("./repl").start_repl


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
  #console.log c, key, v

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

module.exports.app = app
