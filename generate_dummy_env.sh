#!/bin/bash

echo "// GENERATED DUMMY FILE FOR WEB BUILD" > lib/env.dart
echo "class Env {" >> lib/env.dart
echo "  static const String NINJA_API_KEY = 'DUMMY_WEB_DO_NOT_USE';" >> lib/env.dart
echo "}" >> lib/env.dart