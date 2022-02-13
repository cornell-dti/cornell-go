FROM node
WORKDIR /app
COPY . .

EXPOSE 80

RUN ["chmod", "+x", "./cd/setup.sh"]
RUN ["chmod", "+x", "./cd/deploy.sh"]

RUN ["bash", "./cd/setup.sh"]
ENTRYPOINT ["bash", "./cd/deploy.sh"]