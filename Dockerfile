FROM node:14.18.1

EXPOSE 80

RUN npm install -g prettier @nestjs/cli jest rimraf

WORKDIR /app/admin
COPY admin/package.json .
RUN npm install

WORKDIR /app/server
COPY server/package.json .
RUN npm install

WORKDIR /app/admin
COPY admin .
RUN npm run build

WORKDIR /app/server
COPY server .
RUN npm run build
ENTRYPOINT ["npm", "run", "start:prod"]