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
  # Hashes,
  "HGET", "HLEN", "HKEYS"
]
app.get '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  #start_repl
  #  req: req
  field = req.query.field
  if c.toUpperCase() not in GET_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      # http://stackoverflow.com/a/3886106/177293
      # #wat?
      if parseInt(dbres) is dbres
        dbres = dbres + ""
      return res.send(dbres)
    else
      res.status(500)
      return res.send(err.toString())

  if field?
    args = [key, field]
  else
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
  # Hashes
  "HSET",
]
app.post '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  field = req.query.field
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

  if field?
    args = [key, field, v, retrn]
  else
    args = [key, v, retrn]
  db[c].apply db, args

module.exports.app = app
