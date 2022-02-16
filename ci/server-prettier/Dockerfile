FROM node:14.18.1

WORKDIR /app/server
COPY server .

RUN npm install -g prettier @nestjs/cli jest rimraf
RUN npm install
RUN npm run checkformat
