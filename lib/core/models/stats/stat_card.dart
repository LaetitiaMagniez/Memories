import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifiers/counter_notifier.dart';

class StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: Text('StatCard avec Riverpod')),
      body: Center(
        child: StatCard(
          title: 'Compteur en temps réel',
          count: count,
          color: Colors.blue,
        ),
      ),
    );
  }
}
