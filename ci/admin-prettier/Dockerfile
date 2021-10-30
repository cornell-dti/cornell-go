FROM node:14.18.1
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/admin-prettier/run.sh"]

ENTRYPOINT [ "ci/admin-prettier/run.sh" ]