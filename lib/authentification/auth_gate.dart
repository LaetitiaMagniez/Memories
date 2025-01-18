import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart'; // Page de connexion
import 'signup.dart'; // Page d'inscription

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Memories'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Connexion'),
                Tab(text: "S'inscrire"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Login(), // Page de connexion
              SignUpPage(), // Page d'inscription
            ],
          ),
        );
      },
    );
  }
}
  
