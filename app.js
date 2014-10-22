// Generated by CoffeeScript 1.8.0

/*
env variables required:

    GITHUB_CLIENT_ID
    GITHUB_CLIENT_SECRET
    REDIRECT_URL
 */

(function() {
  var GET_COMMANDS, GITHUB_AUTH_HASH, GITHUB_TOKEN_SET, POST_COMMANDS, RESTRICTED_KEYS, app, db, express, favicon, https, logger, oauth, _ref,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  express = require("express");

  favicon = require("serve-favicon");

  https = require("https");

  logger = require("morgan");

  oauth = require("oauth-express");

  db = require("./db").db;

  _ref = require("./constants"), GITHUB_TOKEN_SET = _ref.GITHUB_TOKEN_SET, GITHUB_AUTH_HASH = _ref.GITHUB_AUTH_HASH, RESTRICTED_KEYS = _ref.RESTRICTED_KEYS;

  require("./ghev");

  app = express();

  app.use(logger());

  app.use(favicon("" + __dirname + "/public/favicon.ico"));

  app.use(function(req, res, next) {
    var data;
    data = '';
    req.setEncoding('utf8');
    req.on('data', function(chunk) {
      return data += chunk;
    });
    return req.on('end', function() {
      req.rawBody = data;
      return next();
    });
  });

  app.get('/auth/:provider', oauth.handlers.auth_provider_redirect);

  app.get('/auth_callback/:provider', oauth.handlers.auth_callback);

  oauth.emitters.github.on('complete', function(result) {
    return db.sadd(GITHUB_TOKEN_SET, result.data.access_token, function(err) {
      if (!err) {
        return db.hset(GITHUB_AUTH_HASH, result.data.access_token, JSON.stringify(result.user_data));
      }
    });
  });

  app.use(function(req, res, next) {
    var token;
    token = req.query["access_token"] || req.headers["access_token"];
    if (token == null) {
      res.status(403).write("Invalid Access Token");
      return res.send();
    }
    return db.sismember(GITHUB_TOKEN_SET, token, function(err, ismemberres) {
      if (err != null) {
        console.log(err.toString());
        res.status(500);
        return res.send();
      }
      if (ismemberres === 1) {
        next();
      } else {
        res.status(403).write("Invalid");
        return res.send();
      }
    });
  });

  app.all('*', function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    return next();
  });

  GET_COMMANDS = ["EXISTS", "DUMP", "PTTL", "GET", "LRANGE", "HGET", "HLEN", "HKEYS"];

  app.get('/:command/:key', function(req, res) {
    var args, c, key, retrn, _ref1;
    c = req.param("command");
    key = req.param("key");
    if (__indexOf.call(RESTRICTED_KEYS, key) >= 0) {
      res.status(403).write("no.");
      return res.send();
    }
    if (_ref1 = c.toUpperCase(), __indexOf.call(GET_COMMANDS, _ref1) < 0) {
      res.status(400).write("unsupported command");
      return res.send();
    }
    retrn = function(err, dbres) {
      if (!err) {
        if (parseInt(dbres) === dbres) {
          dbres = dbres + "";
        }
        if ("jsonp" in req.query) {
          res.status(200).jsonp(dbres);
          return res.send();
        } else {
          return res.send(dbres);
        }
      } else {
        res.status(500);
        return res.send(err.toString());
      }
    };
    args = [key];
    if (req.query.args != null) {
      args.push.apply(args, req.query.args.split(','));
    }
    args.push(retrn);
    return db[c].apply(db, args);
  });

  POST_COMMANDS = ["DEL", "RESTORE", "EXPIRE", "PEXPIRE", "INCR", "DECR", "APPEND", "SET", "LPUSH", "HSET"];

  app.post('/:command/:key', function(req, res) {
    var args, c, key, retrn, v, _ref1;
    c = req.param("command");
    key = req.param("key");
    if (__indexOf.call(RESTRICTED_KEYS, key) >= 0) {
      res.status(403).write("no.");
      return res.send();
    }
    v = req.rawBody;
    if (_ref1 = c.toUpperCase(), __indexOf.call(POST_COMMANDS, _ref1) < 0) {
      res.status(400).write("unsupported command");
      return res.send();
    }
    retrn = function(err, dbres) {
      var content;
      if (!err) {
        content = (dbres + "") || "true";
        return res.send(content);
      } else {
        res.status(500);
        return res.send(err.toString());
      }
    };
    args = [key];
    if (req.query.args != null) {
      args.push.apply(args, req.query.args.split(','));
    }
    args.push.apply(args, [v, retrn]);
    return db[c].apply(db, args);
  });

  module.exports.app = app;

}).call(this);
