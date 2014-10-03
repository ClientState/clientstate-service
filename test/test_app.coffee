request = require 'supertest'
repl = require 'repl'

app = require('../app').app
db = require('../db').db



describe 'GET, SET, APPEND', () ->
  db.flushall()

  it 'GET returns an empty response', (done) ->
    request(app)
      .get('/get/foobar')
      .expect(200)
      .expect("", done)

  it 'SET returns true', (done) ->
    request(app)
      .post('/set/foobar')
      .send('baz')
      .expect(200)
      .expect("true", done)

  it 'GET returns the stored value', (done) ->
    request(app)
      .get('/get/foobar')
      .expect(200)
      .expect("baz", done)

  it 'APPEND returns true', (done) ->
    request(app)
      .post('/append/foobar')
      .send('quux')
      .expect("true", done)

  it 'GET returns the appended value', (done) ->
    request(app)
      .get('/get/foobar')
      .expect("bazquux", done)

describe 'LPUSH, LRANGE', () ->
  db.flushall()

  it 'LRANGE needs args', (done) ->
    request(app)
      .get('/lrange/baz')
      # should be a 4XX?
      .expect(500)
      .expect(/wrong number of arguments/, done)

  it 'LRANGE returns empty list', (done) ->
    request(app)
      .get('/lrange/baz?args=0,-1')
      .expect('[]', done)

  it 'LPUSH returns true', (done) ->
    request(app)
      .post('/lpush/baz')
      .send('rawness')
      .expect('true', done)

  it 'LRANGE returns the value', (done) ->
    request(app)
      .get('/lrange/baz?args=0,1')
      .expect('["rawness"]', done)

describe 'HGET, HSET, HLEN, HKEYS', () ->
  db.flushall()

  it "HSET sets field's value", (done) ->
    request(app)
      .post('/hset/foo?field=bar')
      .send('baz')
      .expect(200)
      .expect('true', done)

  it 'HGET returns value', (done) ->
    request(app)
      .get('/hget/foo?field=bar')
      .expect('baz', done)

  it 'HLEN returns length', (done) ->
    request(app)
      .get('/hlen/foo')
      .expect(200)
      .expect('1', done)

  it 'HKEYS returns keys', (done) ->
    request(app)
      .get('/hkeys/foo')
      .expect(200)
      .expect('["bar"]', done)


