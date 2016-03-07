#!/bin/bash

set -e

if [ "$1" = 'init' ]; then
  systemctl daemon-reload
fi

exec "$@"

