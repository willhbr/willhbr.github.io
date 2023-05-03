#!/bin/bash

set -x

exec podman run --userns '' --mount type=bind,src=.,dst=/src \
  --publish ${1:-4000}:4000 --rm -it willhbr.github.io
