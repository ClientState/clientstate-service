express = require "express"
repl = require "repl"
favicon = require "serve-favicon"
https = require "https"
querystring = require "querystring"

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

GITHUB_TOKEN_SET = "__github_token_set"
GITHUB_AUTH_HASH = "__github_auth_hash"
RESTRICTED_KEYS = [
  GITHUB_TOKEN_SET,
  GITHUB_AUTH_HASH,
]

app.get '/auth_callback', (req, res) ->
  code = req.query.code
  # when we build the app in the docker,
  # we set these parameters.
  client_id = process.env.GITHUB_CLIENT_ID
  client_secret = process.env.GITHUB_CLIENT_SECRET
  console.log code, client_id, client_secret

  post_data = querystring.stringify {
    code: code
    client_id: client_id
    client_secret: client_secret
  }
  options =
    method: 'POST'
    host: 'github.com'
    path: '/login/oauth/access_token'
    headers: {
      "User-Agent": "skyl/hello-express"
      "Accept": "application/json"
    }
  cb = (gh_response) ->
    console.log "POST callback!"
    str = ''
    gh_response.on 'data', (chunk) ->
      str += chunk
    gh_response.on 'end', () ->
      console.log str
      if gh_response.statusCode is 200
        console.log "SAVING FROM GITHUB!"
        access_token = JSON.parse(str).access_token
        db.sadd GITHUB_TOKEN_SET, access_token

        options =
          host: 'api.github.com'
          path: "/user?access_token=#{access_token}"
          headers: {
            "User-Agent": "skyl/hello-express"
          }
        user_req = https.request options, (gh_response) ->
          str = ''
          gh_response.on 'data', (chunk) -> str += chunk
          gh_response.on 'end', () ->
            console.log str
            db.hset GITHUB_AUTH_HASH, access_token, str
        user_req.end()
        res.status(200).write("OK")
        return res.send()
      else
        res.status(403).write("Invalid")
        return res.send()
  req = https.request(options, cb)
  req.write post_data
  req.end()




app.use (req, res, next) ->
  key = req.param "key"
  if key in RESTRICTED_KEYS
    res.status(403).write("no.")
    return res.send()
  next()

# authenticate with github token
app.use (req, res, next) ->
  token = req.query["access_token"] or req.headers["access_token"]
  if not token?
    res.status(403).write("Invalid Access Token")
    return res.send()
  db.sismember GITHUB_TOKEN_SET, token, (err, ismemberres) ->
    # what would the err be?
    if err?
      res.status(500).write(err.toString())
      return res.send()
    if ismemberres is 1
      next()
      return
    # not in our set
    else
      res.status(403).write("Invalid")
      return res.send()


GET_COMMANDS = [
  # Keys
  "EXISTS", "DUMP",
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
  # Keys
  "DEL",
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
module.exports.GITHUB_TOKEN_SET = GITHUB_TOKEN_SET
module.exports.GITHUB_AUTH_HASH = GITHUB_AUTH_HASH
