#!/bin/bash

DEBIAN_FRONTEND=noninteractive
npm install -g prettier nest jest rimraf
cd admin
npm install
npm run build