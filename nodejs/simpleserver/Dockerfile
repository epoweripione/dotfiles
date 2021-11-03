FROM node:12-alpine

WORKDIR /srv/simpleserver

COPY . .

RUN npm install

EXPOSE 8080

CMD ["node", "server.js"]