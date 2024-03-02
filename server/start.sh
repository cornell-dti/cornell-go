#!/bin/bash

if [ ${DEVELOPMENT} != "true" ]; then 
  npm run start:prod; 
elif [ ${TESTING_UNIT} = "true" ]; then 
  npm run test;  
elif [ ${TESTING_E2E} = "true" ]; then 
  npm run test:e2e; 
else 
  npm run start;
fi