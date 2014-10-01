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
