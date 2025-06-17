import 'package:js/js.dart';
import 'dart:js_interop';

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
  return env?.NINJA_API_KEY?.toDart ?? '';
}
