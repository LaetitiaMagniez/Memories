import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';
import 'package:memories_project/features/authentification/password/forgotten_password.dart';
import '../../../core/views/home.dart';
import '../../../core/services/authentification_service.dart';
import '../../../core/widgets/authentification/social_login_buttons.dart';

// Aucune import à modifier

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthentificationService authentificationService = AuthentificationService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _hidePasswordField = false;
  bool _isBiometricAvailable = false;
  bool _hasAttemptedBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    if (kIsWeb) {
      setState(() => _isBiometricAvailable = false);
      return;
    }

    final canAuthenticate = await authentificationService.canCheckBiometrics();
    setState(() {
      _isBiometricAvailable = canAuthenticate;
    });

    if (canAuthenticate && !_hasAttemptedBiometric) {
      _hasAttemptedBiometric = true;
      _attemptAutoBiometricLogin();
    }
  }

  Future<void> _loadSavedCredentials() async {
    final remember = await authentificationService.loadRememberMeState();
    if (remember) {
      final savedEmail = await authentificationService.loadEmail();
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _attemptAutoBiometricLogin() async {
    final rememberMe = await authentificationService.loadRememberMeState();
    if (!rememberMe) return;

    final didAuthenticate = await authentificationService.authenticateWithBiometrics();

    if (didAuthenticate) {
      final success = await authentificationService.biometricLogin();
      if (success && mounted) {
        setState(() => _hidePasswordField = true);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      }
    }
  }

  Future<void> login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (_rememberMe) {
          await authentificationService.saveRememberMeState(
            true,
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          await authentificationService.saveRememberMeState(false, '', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion réussie')),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = "Utilisateur non trouvé.";
            break;
          case 'wrong-password':
            message = "Mot de passe incorrect.";
            break;
          default:
            message = "Une erreur est survenue : ${e.message}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Veuillez entrer un email.";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Veuillez entrer un email valide.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!_hidePasswordField)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez entrer votre mot de passe.";
                        }
                        return null;
                      },
                    ),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value!);
                        },
                      ),
                      const Text('Se souvenir de moi'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Se connecter'),
                  ),
                  SocialLoginButtons(
                    onGooglePressed: () => authentificationService.signInWithGoogle(context),
                    onFacebookPressed: () => authentificationService.signInWithFacebook(context),
                  ),
                  if (_isBiometricAvailable)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'Vous pouvez également vous connecter avec votre empreinte digitale',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const ForgottenPasswordPage(),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}