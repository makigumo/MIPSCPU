#!/bin/sh
exec docker run --rm --user="$(id -u):$(id -g)" --net=none -v "$PWD":/data makigumo/hoppersdk-linux-docker ./build.sh
