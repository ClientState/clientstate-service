// Generated by CoffeeScript 1.8.0
(function() {
  var GET_COMMANDS, POST_COMMANDS, app, db, express, favicon, redis, repl, server, start,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  express = require("express");

  redis = require("redis");

  repl = require("repl");

  favicon = require("serve-favicon");

  app = express();

  app.use(favicon("" + __dirname + "/public/favicon.ico"));

  db = redis.createClient();

  start = function(context) {
    var k, r, v, _results;
    r = repl.start("> ");
    _results = [];
    for (k in context) {
      v = context[k];
      _results.push(r.context[k] = v);
    }
    return _results;
  };

  GET_COMMANDS = ["GET"];

  app.get('/:command/:key', function(req, res) {
    var c, key, _ref;
    c = req.param("command");
    key = req.param("key");
    if (_ref = c.toUpperCase(), __indexOf.call(GET_COMMANDS, _ref) < 0) {
      res.status(400).write("unsupported command");
      return res.send();
    }
    return db[c](key, function(err, dbres) {
      return res.send(dbres);
    });
  });

  POST_COMMANDS = ["SET"];

  app.post('/:command/:key', function(req, res) {
    var c, key, v, _ref;
    c = req.param("command");
    key = req.param("key");
    v = req.query["v"];
    if (_ref = c.toUpperCase(), __indexOf.call(POST_COMMANDS, _ref) < 0) {
      res.status(400).write("unsupported command");
      return res.send();
    }
    return db[c](key, v, function(err, dbres) {
      if (!err) {
        return res.send("true");
      } else {
        res.status(500);
        return res.send(err.toString());
      }
    });
  });


  /*
  logErrors = (err, req, res, next) ->
    console.error err.stack
    next err
  
  app.use logErrors
   */

  server = app.listen(3000, function() {
    return console.log('Listening on port %d', server.address().port);
  });

}).call(this);
