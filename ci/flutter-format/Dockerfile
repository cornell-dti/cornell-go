FROM ghcr.io/cirruslabs/flutter

WORKDIR /app/game
COPY game .

RUN flutter format lib | grep '0 changed'
