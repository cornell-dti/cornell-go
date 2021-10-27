#!/bin/bash

apt update
apt install -y nodejs npm
cd server
npm install
npm run build