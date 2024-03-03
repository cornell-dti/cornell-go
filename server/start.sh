#!/bin/bash

npx prisma migrate deploy || true

if [ $DEVELOPMENT = "false" ]; then 
  npm run start:prod; 
elif [ $TESTING_UNIT = "true" ]; then 
  npm run test;  
elif [ $TESTING_E2E = "true" ]; then 
  npm run test:e2e; 
else 
  npm run start;
fi