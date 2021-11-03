#!/usr/bin/env bash

# https://docs.nestjs.com/
PRJ_NAME=${1:-"nest"}

npm i -g @nestjs/cli

nest new "${PRJ_NAME}"

cd "${PRJ_NAME}" && npm run start
