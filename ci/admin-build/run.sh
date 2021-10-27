#!/bin/bash

DEBIAN_FRONTEND=noninteractive
npm install -g prettier @nestjs/cli jest rimraf yarn
cd admin
npm install
npm run build