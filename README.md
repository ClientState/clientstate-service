Run locally
===========

You have node and npm installed? Good.

    npm install

Do you have redis installed with `redis-server` on your PATH? Good.

    ./run_tests.sh

Run dev server

    node server

Set environment variables for the service:

    GITHUB_CLIENT_ID
    GITHUB_CLIENT_SECRET
    OAUTH_REDIRECT_URL

So, if you launched a clientstate-js app on localhost:8090,
you would make your make OAUTH_REDIRECT_URL="http://localhost:8090".
Or, "https://yourapp.com" in production.


Run Locally With Docker
=======================

Run redis:

    docker run -d --name redis -p 6379:6379 redis

Build clientstate, after cloning this repository:

    docker build -t skyl/clientstate-redis .
    docker run -itd \
    -e "GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID" \
    -e "GITHUB_CLIENT_SECRET=$GITHUB_CLIENT_SECRET" \
    -e "OAUTH_REDIRECT_URL=http://localhost:8090" \
    -p 3000:3000 --name cs-redis --link redis:redis skyl/clientstate-redis

Now you have port 0.0.0.0:3000 published to the docker server machine
and talking to the redis container.

`docker ps` and `docker kill` to stop the containers.


Authenticate and use the service with a browser
================================================

see https://github.com/ClientState/clientstate-js
