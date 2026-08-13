#!/bin/sh
set -e

REPO=$1
shift

case "$1" in
  --ref)
    git clone --depth 1 --single-branch --branch "$2" "$REPO" .
    ;;
  --commit)
    git clone "$REPO" .
    git checkout "$2"
    ;;
  *)
    echo "Usage: $0 <repo> --ref <tag> | --commit <sha>" >&2
    exit 1
    ;;
esac
