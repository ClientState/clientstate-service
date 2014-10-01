redis = require "redis"
REDIS_PORT = process.env.REDIS_PORT or 6379

db = redis.createClient REDIS_PORT
module.exports.db = db
