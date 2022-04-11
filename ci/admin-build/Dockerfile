FROM node:14.18.1

WORKDIR /app/admin
COPY admin .

RUN npm install -g prettier @nestjs/cli jest rimraf
RUN npm install
RUN npm run build
