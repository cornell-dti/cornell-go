#!/bin/bash

DEBIAN_FRONTEND=noninteractive
cd server
npm install
npm run build
cd ../admin
npm install
npm run build
cd ..