import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/models/chosen_file.dart';

void main() {
  test('ChosenFile stores bytes and name correctly', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final name = 'file.png';

    final chosenFile = ChosenFile(bytes: bytes, name: name);

    expect(chosenFile.bytes, bytes);
    expect(chosenFile.name, name);
  });
}
