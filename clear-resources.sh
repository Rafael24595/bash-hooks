#!/bin/bash

REMOTE_LOCATION="./.remote-scripts"

if [[ ! -f "$REMOTE_LOCATION" ]]; then
    exit 0
fi

rm -r $REMOTE_LOCATION