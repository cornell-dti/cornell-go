# CornellGO!

CornellGO! is an interactive scavenger hunt aimed at sparking interest in exploring the historic Cornell campus by leading the player around campus, seeking landmarks while competing with others.

This repository contains the Flutter mobile app, the React administration app, and the Nest.js backend. Visit each subfolder for a description of each project's installation.

### Full project startup

```
cd ./server
npm install
cd ../admin
npm install
cd ../game
flutter pub get
```

### Run project in container (make sure to run the npm installs before to prevent a very long startup)

```
docker compose up
```

### Restart the container

```
docker compose restart
```

### Stop the container

```
Mac OS: Command + C
Other: Control + C
```

### Delete container artifacts

```
docker compose down
rm -rf ./postgres-data
```

### Start the server based on .env in the `server` folder

```
cd server
npm run start
```

### Start the frontend without a backend running

```
cd admin
npm start
```

### Start the flutter app without a backend running

```
Open the main.dart file, then click the Play button
```

## Contributors


### SP22 
- **Nikita Kasumov** - TPM/PM 
- **Eric Huang** - Developer 
- **Youssef Attia** - Developer
- **Cathryn Li** - Developer
- **Nirbhay S Narang (nick) ** - Developer

### FA21
- **Nikita Kasumov** - TPM/PM
- **Boao Dong** - Backend Developer
- **Eric Huang** - Administrative Frontend
