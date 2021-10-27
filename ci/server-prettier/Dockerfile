FROM node
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/server-prettier/run.sh"]

ENTRYPOINT [ "ci/server-prettier/run.sh" ]