#!/bin/bash

echo "// GENERATED FILE - DO NOT EDIT" > lib/env.dart
echo "class Env {" >> lib/env.dart

while IFS= read -r line
do
  if [[ $line == *=* ]]; then
    key=$(echo $line | cut -d '=' -f 1)
    value=$(echo $line | cut -d '=' -f 2-)
    echo "  static const String $key = '$value';" >> lib/env.dart
  fi
done < .env.android

echo "}" >> lib/env.dart
