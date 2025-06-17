import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:js/js.dart';
import 'dart:js_interop';
import '../../../env.dart' if (dart.library.js) '../../../env_dummy.dart';

@JS('env')
external _EnvJS? get env;

@JS()
@anonymous
@staticInterop
class _EnvJS {}

extension _EnvJSKeys on _EnvJS {
  external JSString? get NINJA_API_KEY;
}

String get ninjaApiKey {
  if (kIsWeb) {
    return env?.NINJA_API_KEY?.toDart ?? '';
  } else {
    return Env.NINJA_API_KEY;
  }
}
