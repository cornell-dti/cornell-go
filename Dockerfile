FROM node:20

EXPOSE 80
EXPOSE 8000

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
RUN chmod +x ./start.sh
RUN npx prisma generate
RUN npm run build
RUN if [ $DEVELOPMENT = "false" ]; then npx prisma migrate deploy; fi

ENTRYPOINT ./start.sh