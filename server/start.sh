#!/bin/sh

npx prisma migrate deploy || true
node src/caslfix.js

if [ $DEVELOPMENT = "false" ]; then 
  npm run start:prod; 
elif [ $DB_RESET = "true" ]; then
  npx prisma db push --accept-data-loss --force-reset
elif [ $TESTING_UNIT = "true" ]; then 
  npm run test;  
elif [ $TESTING_E2E = "true" ]; then 
  npm run test:e2e; 
else 
  npm run start;
fi