FROM ubuntu
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/server-build/run.sh"]

ENTRYPOINT [ "ci/server-build/run.sh" ]