request = require 'supertest'

app = require('../app').app
db = require('../db').db

GITHUB_TOKEN_SET = require('../app').GITHUB_TOKEN_SET
GITHUB_AUTH_HASH = require('../app').GITHUB_AUTH_HASH

skyl = {
  "login": "skyl",
  "id": 61438,
  "avatar_url": "https://avatars.githubusercontent.com/u/61438?v=2",
  "gravatar_id": "",
  "url": "https://api.github.com/users/skyl",
  "html_url": "https://github.com/skyl",
  "followers_url": "https://api.github.com/users/skyl/followers",
  "following_url": "https://api.github.com/users/skyl/following{/other_user}",
  "gists_url": "https://api.github.com/users/skyl/gists{/gist_id}",
  "starred_url": "https://api.github.com/users/skyl/starred{/owner}{/repo}",
  "subscriptions_url": "https://api.github.com/users/skyl/subscriptions",
  "organizations_url": "https://api.github.com/users/skyl/orgs",
  "repos_url": "https://api.github.com/users/skyl/repos",
  "events_url": "https://api.github.com/users/skyl/events{/privacy}",
  "received_events_url": "https://api.github.com/users/skyl/received_events",
  "type": "User",
  "site_admin": false,
  "name": "Skylar Saveland",
  "company": "JPMorgan Chase",
  "blog": "http://skyl.org/",
  "location": "San Francisco",
  "email": "skylar.saveland@gmail.com",
  "hireable": true,
  "bio": null,
  "public_repos": 101,
  "public_gists": 30,
  "followers": 56,
  "following": 125,
  "created_at": "2009-03-09T01:41:19Z",
  "updated_at": "2014-10-02T05:07:10Z"
}


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

  # this one requires network access, hrm.
  if process.env.TEST_USE_NETWORK
    it 'calls github with invalid token and rejects', (done) ->
      request(app)
        .get("/get/foobar")
        .set({"access_token": "NOWAYTHISISAREALTOKEN"})
        .expect(403, done)


describe 'KEYS - DEL, EXISTS', () ->
  resetdb()
  it 'EXISTS returns 1 for existing key', (done) ->
    db.set('beans', 'pork')
    request(app)
      .get('/exists/beans')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("1", done)
  it 'DEL returns true', (done) ->
    request(app)
      .post('/del/beans')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("true", done)
  it 'EXISTS now returns 0', (done) ->
    request(app)
      .get('/exists/beans')
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

  it 'SET returns true', (done) ->
    request(app)
      .post('/set/foobar')
      .set({"access_token": "TESTTOKEN"})
      .send('baz')
      .expect(200)
      .expect("true", done)

  it 'GET returns the stored value', (done) ->
    request(app)
      .get('/get/foobar')
      .set({"access_token": "TESTTOKEN"})
      .expect(200)
      .expect("baz", done)

  it 'APPEND returns true', (done) ->
    request(app)
      .post('/append/foobar')
      .set({"access_token": "TESTTOKEN"})
      .send('quux')
      .expect("true", done)

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

  it 'LPUSH returns true', (done) ->
    request(app)
      .post('/lpush/baz')
      .set({"access_token": "TESTTOKEN"})
      .send('rawness')
      .expect('true', done)

  it 'LRANGE returns the value', (done) ->
    request(app)
      .get('/lrange/baz?args=0,1')
      .set({"access_token": "TESTTOKEN"})
      .expect('["rawness"]', done)


describe 'HGET, HSET, HLEN, HKEYS', () ->
  resetdb()

  it "HSET sets field's value", (done) ->
    request(app)
      .post('/hset/foo?field=bar')
      .set({"access_token": "TESTTOKEN"})
      .send('baz')
      .expect(200)
      .expect('true', done)

  it 'HGET returns value', (done) ->
    request(app)
      .get('/hget/foo?field=bar')
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
