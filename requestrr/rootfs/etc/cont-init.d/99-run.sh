#!/bin/bash

# Initialize config
cp -rnf /root/config/* /config/

# Start app
/app/requestrr/bin/Requestrr.WebApi -c /config
