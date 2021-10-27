FROM ubuntu
WORKDIR /app
COPY . .
RUN ["./cd/setup.sh"]
ENTRYPOINT [ "./cd/deploy.sh" ]