FROM node:14.18.1
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/server-prettier/run.sh"]

ENTRYPOINT [ "ci/server-prettier/run.sh" ]