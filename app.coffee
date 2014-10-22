###
env variables required:

    GITHUB_CLIENT_ID
    GITHUB_CLIENT_SECRET
    REDIRECT_URL
###

express = require "express"
favicon = require "serve-favicon"
https = require "https"
logger = require "morgan"
oauth = require "oauth-express"

# node_redis client
{db} = require "./db"
{
 GITHUB_TOKEN_SET
 GITHUB_AUTH_HASH
 RESTRICTED_KEYS
} = require "./constants"
require "./ghev"
#global.gh = gh

app = express()

app.use logger()
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


# oauth-express
app.get '/auth/:provider', oauth.handlers.auth_provider_redirect
app.get '/auth_callback/:provider', oauth.handlers.auth_callback
oauth.emitters.github.on 'complete', (result) ->
  db.sadd GITHUB_TOKEN_SET, result.data.access_token, (err) ->
    if not err
      db.hset GITHUB_AUTH_HASH, result.data.access_token, JSON.stringify(result.user_data)


# authenticate with github token
app.use (req, res, next) ->
  token = req.query["access_token"] or req.headers["access_token"]
  if not token?
    res.status(403).write("Invalid Access Token")
    return res.send()
  db.sismember GITHUB_TOKEN_SET, token, (err, ismemberres) ->
    # what would the err be?
    # TODO: this is not production-ready, eh?
    if err?
      console.log(err.toString())
      res.status(500)
      return res.send()
    if ismemberres is 1
      next()
      return
    # not in our set
    else
      res.status(403).write("Invalid")
      return res.send()


app.all '*', (req, res, next) ->
  # TODO - limit to given origin?
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers",
             "Origin, X-Requested-With, Content-Type, Accept"
  res.header "Access-Control-Allow-Methods",
             "GET, POST, OPTIONS"
  next()


GET_COMMANDS = [
  # Keys
  "EXISTS", "DUMP", "PTTL",
  # Strings
  "GET",
  # Lists
  "LRANGE",
  # Hashes,
  "HGET", "HLEN", "HKEYS"
]
app.get '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  if key in RESTRICTED_KEYS
    res.status(403).write("no.")
    return res.send()

  if c.toUpperCase() not in GET_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      # http://stackoverflow.com/a/3886106/177293
      # #wat?
      if parseInt(dbres) is dbres
        dbres = dbres + ""
      if "jsonp" of req.query
        res.status(200).jsonp dbres
        return res.send()
      else
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
  # Keys
  "DEL", "RESTORE", "EXPIRE", "PEXPIRE",
  "INCR", "DECR"
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
  if key in RESTRICTED_KEYS
    res.status(403).write("no.")
    return res.send()
  v = req.rawBody

  if c.toUpperCase() not in POST_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      content = (dbres + "") or "true"
      return res.send content
    else
      res.status(500)
      return res.send(err.toString())

  args = [key]
  if req.query.args?
    args.push.apply args, req.query.args.split ','
  args.push.apply args, [v, retrn]
  db[c].apply db, args

module.exports.app = app
