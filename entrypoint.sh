#!/bin/sh
set -eu

dumb-init /usr/bin/code-server --disable-telemetry "$@"