#!/bin/bash

DEBIAN_FRONTEND=noninteractive
npm install -g prettier @nestjs/cli jest rimraf
cd server
npm install
npm run checkformat