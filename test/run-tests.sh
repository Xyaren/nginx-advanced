#!/bin/bash
set -e

cd "$(dirname "$0")"

trap 'docker compose down' EXIT

if [[ "$1" == "--no-build" ]]; then
  docker compose up -d
else
  docker compose up -d --build
fi
sleep 2

hurl --test suites/
