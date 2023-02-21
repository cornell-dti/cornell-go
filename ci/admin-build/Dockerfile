FROM node:18.14.0

WORKDIR /app/admin
COPY admin .

RUN npm install -g prettier @nestjs/cli jest rimraf
RUN npm install
RUN npm run build
