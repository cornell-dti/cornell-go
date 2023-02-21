FROM node:18.14.0

WORKDIR /app/server
COPY server .

RUN npm install -g prettier @nestjs/cli jest rimraf
RUN npm install
RUN npm run checkformat
