repl = require "repl"

start_repl = (context) ->
  r = repl.start("> ")
  for k,v of context
    r.context[k] = v

module.exports.start_repl = start_repl
