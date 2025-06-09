import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'profile_page_mobile.dart';
import 'profile_page_web.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ProfilePageWeb();
    } else {
      return const ProfilePageMobile();
    }
  }
}
