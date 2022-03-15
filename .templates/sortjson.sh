#!/bin/bash

for files in */*.json; do
jq --sort-keys . "$files" > config2.json && cat config2.json > "$files" && rm config2.json
done
