# Inherit from Heroku's stack
FROM node:8.16.1-alpine

RUN apk add --update alpine-sdk libtool autoconf automake python libsodium-dev
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . . 
RUN npm build
ENV PATH="/usr/src/app/node_modules/.bin:/usr/src/app/node_modules/hubot/node_modules/.bin:${PATH}"
EXPOSE 3000
CMD ["/usr/src/app/node_modules/.bin/hubot", "--name", "Librarian", "-a", "discord"]
