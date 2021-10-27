#!/bin/bash

apt update
apt install -y nodejs npm
cd admin
npm install
npm run checkformat