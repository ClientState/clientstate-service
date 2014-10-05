{app} = require "./app"

server = app.listen 3000, () ->
  console.log 'Listening on port %d', server.address().port
