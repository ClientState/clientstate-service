FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y nodejs npm git git-core

COPY . /srv
# set the working directory to run commands from
WORKDIR /srv
RUN npm install
# expose the port so host can have access
EXPOSE 3000
# pass env variables in with docker run -e
# GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, OAUTH_REDIRECT_URL
CMD ["nodejs", "server.js"]
