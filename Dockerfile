FROM ubuntu
WORKDIR /app
COPY . .

RUN ["chmod", "+x", "./cd/setup.sh"]
RUN ["chmod", "+x", "./cd/deploy.sh"]

RUN ["./cd/setup.sh"]
ENTRYPOINT [ "./cd/deploy.sh" ]