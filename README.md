On a host development machine
=============================

You have node and npm installed? Good.

Run `npm install`.

Do you have redis installed with `redis-server` on your PATH? Good.

Run `./run_tests.sh`


With docker
===========

Run redis:

    docker run -d --name redis -p 6379:6379 redis

Build clientstate after cloning this repository:

    docker build -t skyl/clientstate-redis .
    docker run -itd -p 3000:3000 --link redis:redis skyl/clientstate-redis

Now you have port 0.0.0.0:3000 published to the docker server machine
and talking to the redis container.

`docker ps` and `docker kill` to stop the containers.


Authenticate and use the service with a browser
================================================

see https://github.com/ClientState/clientstate-redis-js
