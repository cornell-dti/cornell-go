# CornellGO!

CornellGO! is an interactive scavenger hunt aimed at sparking interest in exploring the historic Cornell campus by leading the player around campus, seeking landmarks while competing with others.

This repository contains the Flutter mobile app, the React administration app, and the NestJS backend. Visit each subfolder for a description of each project's installation.

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

### Run project in container

```
docker compose up --build
```

### Start the container in the background

```
docker compose up --build -d
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

### Start the frontend (for debugging)

```
cd admin
npm start
```

### Start the flutter app

```
Open the main.dart file, then click the Play button
*OR* to run with a custom server url

cd game
flutter run --dart-define="API_URL=https://example.com"
```

### Generate docs

```
cd server
npm run doc
```

### Reset database or test a new schema

```
npm run dbreset
```

### Create a database migration

```
npm run dbmigrate -- my_migration
```

## Contributors

### SP23

- **Youssef Attia** - Developer
- **Cathryn Li** - Developer
- **Nirbhay S Narang** - Developer
- **Chris Gu** - Developer
- **Brian La** - Developer
- **Valerie Wong** - Designer
- **Hanan Abraha** - Designer
- **Alisha Lin** - PMM
- **Nikita Kasumov** - TPM
- **Jesse Cheng** - APM
- **Althea Bata** - PM

### FA22

- **Youssef Attia** - Developer
- **Cathryn Li** - Developer
- **Nirbhay S Narang** - Developer
- **Chris Gu** - Developer
- **Brian La** - Developer
- **Robin Ahn** - Designer
- **Hanan Abraha** - Designer
- **Alisha Lin** - PMM
- **Nikita Kasumov** - TPM
- **Althea Bata** - PM

### SP22

- **Eric Huang** - Developer
- **Youssef Attia** - Developer
- **Cathryn Li** - Developer
- **Nirbhay S Narang** - Developer
- **Chris Gu** - Developer
- **Brian La** - Developer
- **Nikita Kasumov** - TPM/PM

### FA21

- **Boao Dong** - Backend Developer
- **Eric Huang** - Administrative Frontend
- **Nikita Kasumov** - TPM/PM
