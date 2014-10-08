redis-server ./test/redis.conf
REDIRECT_URL=https://localhost:3000 REDIS_PORT=6380 mocha
kill `cat redis.pid`
