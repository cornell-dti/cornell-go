#!/bin/bash

DEBIAN_FRONTEND=noninteractive
npm install -g prettier nest jest rimraf
cd server
npm install
npm run checkformat