# CornellGO!

CornellGO! is an interactive scavenger hunt aimed at sparking interest in exploring the historic Cornell campus by leading the player around campus, seeking landmarks while competing with others.

This repository contains the Flutter mobile app, the React administration app, and the Nest.js backend. Visit each subfolder for a description of each project's installation.

### Full project setup

```
mkdir postgres-data
cd ./server
npm install
cd ../admin
npm install
cd ../game
flutter pub get
```

### Update container with new changes

```
docker compose build
```

### Run project in container

```
docker compose build
docker compose up
```

### Start the container in the background (for flutter/react frontend)

```
docker compose restart
```

### Stop the container

```
Press Control + C
*OR* (if done in the background)
docker compose stop
```

### Delete container artifacts

```
docker compose down
rm -rf ./postgres-data
mkdir postgres-data
```

### Start the frontend

```
cd admin
npm start
```

### Start the flutter app

```
Open the main.dart file, then click the Play button
```

## Contributors

### SP22

- **Nikita Kasumov** - TPM/PM
- **Eric Huang** - Developer
- **Youssef Attia** - Developer
- **Cathryn Li** - Developer
- **Nirbhay S Narang** - Developer
- **Chris Gu** - Developer
- **Brian La** - Developer

### FA21

- **Nikita Kasumov** - TPM/PM
- **Boao Dong** - Backend Developer
- **Eric Huang** - Administrative Frontend
