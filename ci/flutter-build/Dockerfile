FROM cirrusci/flutter

WORKDIR /app/game
COPY game .

WORKDIR /app/game/lib
RUN ls

WORKDIR /app/game/lib/widgets
RUN ls

WORKDIR /app/game
RUN flutter build web
