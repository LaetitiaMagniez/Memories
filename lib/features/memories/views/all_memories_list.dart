import 'package:flutter/cupertino.dart';
import 'all_memories_mobile_view.dart';
import 'all_memories_web_view.dart';

class AllMemoriesPage extends StatelessWidget {
  const AllMemoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 800) {
      return const AllMemoriesMobileView();  // Version mobile
    } else {
      return const AllMemoriesWebView();     // Version web
    }
  }
}
