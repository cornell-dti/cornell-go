FROM ubuntu
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "ci/admin-prettier/run.sh"]

ENTRYPOINT [ "ci/admin-prettier/run.sh" ]