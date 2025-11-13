FROM ghcr.io/cirruslabs/flutter

WORKDIR /app/game
COPY game .

RUN flutter pub get
RUN dart format lib | grep '0 changed'
