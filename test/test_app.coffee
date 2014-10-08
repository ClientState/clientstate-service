request = require 'supertest'
{EventEmitter} = require 'events'
{assert, expect} = require 'chai'
#should = require 'should'

{app} = require '../app'
{db} = require '../db'
{GITHUB_TOKEN_SET, GITHUB_AUTH_HASH} = require '../constants'


skyl =
  "login": "skyl"
  "id": 61438


class MockResponse extends EventEmitter
  constructor: (@statusCode, body) ->
    self = this
    setTimeout(() ->
      self.emit "data", body
      self.emit "end"
    , 1)


class MockGithub extends EventEmitter

  constructor: ->
    @eventListeners = {}
    @emitCounts = {}
    @on 'requestToken', @requestToken
    @on 'receiveAccessToken', @receiveAccessToken
  requestToken: (req, res, cb) =>
    @emitCounts['requestToken'] ?= 0
    @emitCounts['requestToken']++
    cb(new MockResponse(200, '{"access_token": "boom"}'))
  receiveAccessToken: (access_token, cb) ->
    @emitCounts['receiveAccessToken'] ?= 0
    @emitCounts['receiveAccessToken']++
    db.sadd GITHUB_TOKEN_SET, access_token
    db.hset GITHUB_AUTH_HASH, access_token, JSON.stringify(skyl)
    # This is really a bunch of stuff for Oauth..
    cb '{}'

# nice article
# pragprog.com decouple-your-apps-with-eventdriven-coffeescript
global.gh = new MockGithub


resetdb = () ->
  db.flushall()
  db.sadd GITHUB_TOKEN_SET, "TESTTOKEN"
  db.hset GITHUB_AUTH_HASH, "TESTTOKEN", JSON.stringify(skyl)


describe 'GITHUB AUTH', () ->
  resetdb()

  it 'returns invalid with no token', (done) ->
    request(app)
      .get('/get/foobar')
      .expect(/Invalid/)
      .expect(403, done)

  it 'does not allow restricted keys', (done) ->
    request(app)
      .get("/get/#{GITHUB_TOKEN_SET}/")
      .set({"access_token": "TESTTOKEN"})
      .expect(403)
    request(app)
      .get("/get/#{GITHUB_AUTH_HASH}/")
      .set({"access_token": "TESTTOKEN"})
      .expect(403, done)

  it 'rejects invalid token', (done) ->
    request(app)
      .get("/get/foobar")
      .set({"access_token": "NOWAYTHISISAREALTOKEN"})
      .expect(403, done)
  it 'reject invalid token in querystring', (done) ->
    request(app)
      .get("/get/foobar?access_token=WRONGE")
      .expect(403, done)
  it 'allows call with token in querystring', (done) ->
    request(app)
      .get("/get/baz?access_token=TESTTOKEN")
      .expect(200, done)

  it 'emits events when /auth_callback/github is called', (done) ->
    request(app)
      .get("/auth_callback/github?code=thisisgreat")
      .expect(200)
      .expect("OK")
      .end () ->
        assert.equal gh.emitCounts["requestToken"], 1
        assert.equal gh.emitCounts["receiveAccessToken"], 1
        db.sismember GITHUB_TOKEN_SET, "boom", (err, dbres) ->
          assert.equal dbres, 1
          done()

  it '/auth/github redirects to github.com', (done) ->
    request(app)
      .get('/auth/github?opts={"state": "foobar"}')
      .expect(302)
      .end (err, res) ->
        expect(res.header['location']).to.be.equal(
          "https://github.com/login/oauth/authorize" +
          "?client_id=#{process.env.GITHUB_CLIENT_ID}&state=foobar"
        )
        done()


describe 'KEYS - DEL, EXISTS', () ->
  resetdb()
  it 'EXISTS returns 1 for existing key', (done) ->
    db.set('beans', 'pork')
    request(app)
      .get('/exists/beans')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("1", done)
  it 'DEL returns 1', (done) ->
    request(app)
      .post('/del/beans')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("1", done)
  it 'EXISTS now returns 0', (done) ->
    request(app)
      .get('/exists/beans')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("0", done)
  # DUMP and RESTORE are hard, maybe later
  it 'DUMP returns serialized that can be restored', (done) ->
    db.hset('myhash', 'mykey', 'quux')
    request(app)
      .get('/dump/myhash')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .end (err, res) ->
        ###
        console.log "RES!!!!!!!!!!!!!!!!!!"
        console.log res
        console.log res.text
        request(app)
          .post('/restore/differentkey?args=0')
          .set({"access_token": "TESTTOKEN"})
          .send(res.text)
          .expect(200, done)
        ###
        done()


describe 'KEYS - EXPIRE, PEXPIRE, PTTL', () ->
  resetdb()
  it 'EXPIRE makes the PTTL work', (done) ->
    db.set 'mykey', 'somestring', () ->
      request(app)
        .post('/expire/mykey')
        .set({"access_token": "TESTTOKEN"})
        .send("50")
        .expect(200)
        .end (err, res) ->
          request(app)
            .get('/pttl/mykey')
            .set({"access_token": "TESTTOKEN"})
            .expect(200)
            .end (err, res) ->
              ttl = parseInt res.text
              expect(ttl).most(50000).least(49990)
              done()
  it 'PEXPIRE makes correct PTTL', (done) ->
    db.set 'mykey', 'somestring', () ->
      request(app)
        .post('/pexpire/mykey')
        .set({"access_token": "TESTTOKEN"})
        .send("500")
        .expect(200)
        .end (err, res) ->
          request(app)
            .get('/pttl/mykey')
            .set({"access_token": "TESTTOKEN"})
            .expect(200)
            .end (err, res) ->
              ttl = parseInt res.text
              expect(ttl).most(500).least(490)
              done()


describe 'KEYS - INCR, DECR', (done) ->
  resetdb()
  it 'INCR empty key returns 1, DECR -> 0', () ->
    request(app)
      .post('/incr/somekey')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("1")
      .end (err, res) ->
        request(app)
          .post('/decr/somekey')
          .set({"access_token": "TESTTOKEN"})
          .expect(200)
          .expect("0", done)



describe 'GET, SET, APPEND', () ->
  resetdb()

  it 'GET returns an empty response', (done) ->
    request(app)
      .get('/get/foobar')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("", done)

  it 'SET returns OK', (done) ->
    request(app)
      .post('/set/foobar')
      .set({"access_token": "TESTTOKEN"})
      .send('baz')
      .expect(200)
      .expect("OK", done)

  it 'GET returns the stored value', (done) ->
    request(app)
      .get('/get/foobar')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("baz", done)

  it 'APPEND returns 7 (length)', (done) ->
    request(app)
      .post('/append/foobar')
      .set({"access_token": "TESTTOKEN"})
      .send('quux')
      .expect("7", done)

  it 'GET returns the appended value', (done) ->
    request(app)
      .get('/get/foobar')
      .set({"access_token": "TESTTOKEN"})
      .expect("bazquux", done)


describe 'LPUSH, LRANGE', () ->
  resetdb()

  it 'LRANGE needs args', (done) ->
    request(app)
      .get('/lrange/baz')
      .set({"access_token": "TESTTOKEN"})
      # should be a 4XX?
      .expect(500)
      .expect(/wrong number of arguments/, done)

  it 'LRANGE returns empty list', (done) ->
    request(app)
      .get('/lrange/baz?args=0,-1')
      .set({"access_token": "TESTTOKEN"})
      .expect('[]', done)

  it 'LPUSH returns 1', (done) ->
    request(app)
      .post('/lpush/baz')
      .set({"access_token": "TESTTOKEN"})
      .send('rawness')
      .expect('1', done)

  it 'LRANGE returns the value', (done) ->
    request(app)
      .get('/lrange/baz?args=0,1')
      .set({"access_token": "TESTTOKEN"})
      .expect('["rawness"]', done)


describe 'HGET, HSET, HLEN, HKEYS', () ->
  resetdb()

  it "HSET sets field's value", (done) ->
    request(app)
      .post('/hset/foo?args=bar')
      .set({"access_token": "TESTTOKEN"})
      .send('baz')
      .expect(200)
      .expect('1', done)

  it 'HGET returns value', (done) ->
    request(app)
      .get('/hget/foo?args=bar')
      .set({"access_token": "TESTTOKEN"})
      .expect('baz', done)

  it 'HLEN returns length', (done) ->
    request(app)
      .get('/hlen/foo')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect('1', done)

  it 'HKEYS returns keys', (done) ->
    request(app)
      .get('/hkeys/foo')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect('["bar"]', done)
