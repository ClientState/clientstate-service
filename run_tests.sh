redis-server ./test/redis.conf
REDIS_PORT=6380 mocha
kill `cat redis.pid`
