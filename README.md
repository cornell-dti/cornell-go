# CornellGO!

CornellGO! is an interactive scavenger hunt aimed at sparking interest in exploring the historic Cornell campus by leading the player around campus, seeking landmarks while competing with others.

This repository contains the Flutter mobile app, the React administration app, and the NestJS backend.

### Full project setup

```
Make sure Node.js, Flutter, and Docker are installed!
npm run setup
```

### API Keys for Flutter

```
To access the Google Maps in the CornellGo app, you need two Google Maps API Keys. One is for Android and one is for iOS. Ask a TPM for the .env file with the keys and the instructions to add it into the app.
```

### Run project in container

```
docker compose up --build
```

### Run project with backend hot reloading

```
docker compose watch

If you want to see logging, run the following in a different terminal:
docker compose logs --follow
Or look at your docker desktop app
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

### Inspect your database data

```
cd server
npx prisma studio
```

### Update API using backend DTOs

```
npm run updateapi
```

### Format all code files

```
npm run formatall
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

### Run unit or integration/end-to-end tests

```
npm run tests:unit
npm run tests:e2e
```

### Reset database or test a new schema

```
npm run dbreset
```

### Create a database migration

```
cd server
npx prisma migrate dev --name my_migration
```

## Contributors

### SP25

- **Temi Adebowale** - Developer
- **Amber Shen** - Developer
- **Jimin Kim** - Developer
- **Ashley Pail** - Designer
- **Jessica Liu** - Designer
- **Sia Harisingani** - Designer
- **Addis Sahle** - PMM
- **Esha Shah** - TPM
- **Joshua Park** - PM
- **Carolyn Wang** - PM

### FA24

- **Jesse Cheng** - Developer
- **Temi Adebowale** - Developer
- **Frank Dai** - Developer
- **Esha Shah** - Developer
- **Happy Li** - Designer
- **Ashley Paik** - Designer
- **Jessica Liu** - Designer
- **Cynthia Lan** - PMM
- **Brian La** - TPM
- **Joshua Park** - PM
- **Carolyn Wang** - PM

### SP24

- **Chris Gu** - Developer
- **Jasmine Li** - Developer
- **Nitya Pakala** - Developer
- **Brian La** - Developer
- **Temi Adebowale** - Developer
- **Happy Li** - Designer
- **James Spokes** - Designer
- **Janet Luo** - PMM
- **Nikita Kasumov** - TPM
- **Cathryn Li** - TPM
- **Jesse Cheng** - PM
- **Joshua Park** - APM

### FA23

- **Tucker Stanley** - Developer
- **Chris Gu** - Developer
- **Jasmine Li** - Developer
- **Nitya Pakala** - Developer
- **Brian La** - Developer
- **Valerie Wong** - Designer
- **Happy Li** - Designer
- **James Spokes** - Designer
- **Janet Luo** - PMM
- **Nikita Kasumov** - TPM
- **Alisha Lin** - APM
- **Jesse Cheng** - PM

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
