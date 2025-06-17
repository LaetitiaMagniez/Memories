import 'dart:typed_data';

class ChosenFile {
  final Uint8List bytes;
  final String name;
  ChosenFile({required this.bytes, required this.name});
}