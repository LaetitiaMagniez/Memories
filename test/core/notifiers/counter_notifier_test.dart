import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/core/notifiers/counter_notifier.dart';

void main() {
  test('CounterNotifier increments state every second', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(counterProvider.notifier);

    expect(container.read(counterProvider), 0);

    await Future.delayed(Duration(milliseconds: 1100));
    expect(container.read(counterProvider), greaterThanOrEqualTo(1));

    await Future.delayed(Duration(seconds: 2));
    expect(container.read(counterProvider), greaterThanOrEqualTo(2));

    notifier.dispose();

    final currentCount = container.read(counterProvider);

    await Future.delayed(Duration(seconds: 2));
    expect(container.read(counterProvider), currentCount);
  });
}
