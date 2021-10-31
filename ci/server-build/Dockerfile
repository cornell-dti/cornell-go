FROM node:14.18.1
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/server-build/run.sh"]

ENTRYPOINT [ "ci/server-build/run.sh" ]