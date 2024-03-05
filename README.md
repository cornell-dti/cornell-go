# CornellGO!

CornellGO! is an interactive scavenger hunt aimed at sparking interest in exploring the historic Cornell campus by leading the player around campus, seeking landmarks while competing with others.

This repository contains the Flutter mobile app, the React administration app, and the NestJS backend.

### Full project setup

```
Make sure Node.js, Flutter, and Docker are installed!
npm run setup
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

### Inspect your database data

```
cd server
npx prisma studio
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

### SP24

- **Chris Gu** - Developer
- **Jasmine Li** - Developer
- **Nitya Pakala** - Developer
- **Brian La** - Developer
- **Happy Li** - Designer
- **James Spokes** - Designer
- **Janet Luo** - PMM
- **Nikita Kasumov** - TPM
- **Cathryn Li** - TPM
- **Jesse Cheng** - PM

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
