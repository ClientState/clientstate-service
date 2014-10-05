{EventEmitter} = require 'events'
https = require 'https'
querystring = require "querystring"
{db} = require "./db"
{GITHUB_TOKEN_SET, GITHUB_AUTH_HASH} = require "./constants"


class Github extends EventEmitter

  constructor: ->
    @on 'requestToken', @requestToken
    @on 'receiveAccessToken', @receiveAccessToken

  requestToken: (req, res, cb) =>
    # a request comes in from github with a code,
    # we want to POST back to github and save the token
    post_data = querystring.stringify {
      code: req.query.code
      client_id: process.env.GITHUB_CLIENT_ID
      client_secret: process.env.GITHUB_CLIENT_SECRET
    }
    console.log post_data
    options =
      method: 'POST'
      host: 'github.com'
      path: '/login/oauth/access_token'
      headers:
        "User-Agent": "skyl/hello-express"
        "Accept": "application/json"

    ghpost = https.request(options, cb)
    ghpost.write post_data
    ghpost.end()

  receiveAccessToken: (access_token, cb) ->
    console.log "SAVING FROM GITHUB!"
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
        cb()
    user_req.end()

#module.exports.gh = new Github
global.gh = new Github
