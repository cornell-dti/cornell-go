FROM ghcr.io/cirruslabs/flutter
ENV FLUTTER_ALLOW_SUPER_USER=true

WORKDIR /app/game
COPY game .

RUN flutter pub get
RUN dart format lib | grep '0 changed'
