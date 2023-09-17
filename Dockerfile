FROM node:18.14.0

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
RUN npx prisma generate
RUN npm run build
RUN if [ ${DEVELOPMENT} != "true" ]; then npx prisma migrate deploy; fi
ENTRYPOINT \
  if [ ${DEVELOPMENT} != "true" ]; then npm run start:prod; \
  elif [ ${TESTING_UNIT} = "true" ]; then npm run test; \ 
  elif [ ${TESTING_E2E} = "true" ]; then npm run test:e2e; \ 
  else npm run start; \
  fi