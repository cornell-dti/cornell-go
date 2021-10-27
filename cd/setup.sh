#!/bin/bash

cd server
npm install
npm run build
cd ../admin
npm install
npm run build
cd ..