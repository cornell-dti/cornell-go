#!/bin/bash

sudo apt install -y nodejs
cd server
npm install
npm run build
cd ../admin
npm install
npm run build
cd ..