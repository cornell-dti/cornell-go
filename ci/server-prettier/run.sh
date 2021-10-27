#!/bin/bash

DEBIAN_FRONTEND=noninteractive
cd server
npm install
npm run checkformat