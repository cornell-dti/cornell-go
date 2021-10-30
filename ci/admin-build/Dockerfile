FROM node:14.18.1
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/admin-build/run.sh"]

ENTRYPOINT [ "ci/admin-build/run.sh" ]