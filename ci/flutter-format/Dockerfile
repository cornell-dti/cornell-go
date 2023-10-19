FROM ghcr.io/cirruslabs/flutter

WORKDIR /app/game
COPY game .

RUN dart format lib | grep '0 changed'
