#!/bin/bash
# If dockerfile failed install manually
nginx -v &>/dev/null || apk add --no-cache nginx
