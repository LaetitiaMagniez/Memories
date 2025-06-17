import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier extends StateNotifier<int> {
  Timer? _timer;

  CounterNotifier() : super(0) {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      state++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});
