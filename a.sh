#!/bin/bash
alias jq=/c/Tmp/jq-win64.exe

for files in */*.json; do
/./c/Tmp/jq-win64.exe --sort-keys . $files > config2.json && cat config2.json > $files && rm config2.json
done
