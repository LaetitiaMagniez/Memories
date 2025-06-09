import 'package:flutter/material.dart';
import '../../../app/home.dart';
import '../../../core/services/authentification_service.dart';
import '../../../core/widgets/authentification/social_login_buttons.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthentificationService authentificationService = AuthentificationService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _showPasswordStrengthInfo = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordStrengthInfo = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final passwordStrength = authentificationService.calculatePasswordStrength(_passwordController.text.trim());

      await authentificationService.signUp(
        context,
        _emailController.text.trim(),
        _passwordController.text.trim(),
        passwordStrength,
      );

      setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordCondition({required bool condition, required String text}) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: condition ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          obscureText: !_isPasswordVisible,
          onChanged: (value) {
            setState(() {
              _passwordStrength = authentificationService.calculatePasswordStrength(value);
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) return "Veuillez entrer un mot de passe.";
            if (value.length < 8) return "Au moins 8 caractères.";
            if (!RegExp(r'[0-9]').hasMatch(value)) return "Au moins un chiffre.";
            if (!RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(value)) {
              return "Au moins un caractère spécial.";
            }
            return null;
          },
        ),
        if (_showPasswordStrengthInfo) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _passwordStrength < 0.5
                  ? Colors.red
                  : _passwordStrength < 0.75
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            authentificationService.getPasswordStrengthText(_passwordStrength),
            style: TextStyle(
              color: _passwordStrength < 0.5
                  ? Colors.red
                  : _passwordStrength < 0.75
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          _buildPasswordCondition(
            condition: _passwordController.text.length >= 8,
            text: "Au moins 8 caractères",
          ),
          _buildPasswordCondition(
            condition: RegExp(r'[0-9]').hasMatch(_passwordController.text),
            text: "Contient au moins un chiffre",
          ),
          _buildPasswordCondition(
            condition: RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(_passwordController.text),
            text: "Contient au moins un caractère spécial",
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Veuillez entrer un email.";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Email invalide.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                buildPasswordField(context),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez confirmer votre mot de passe.";
                    }
                    if (value != _passwordController.text) {
                      return "Les mots de passe ne correspondent pas.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: () => _register(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("S'inscrire"),
                ),
                SocialLoginButtons(
                  onGooglePressed: () => authentificationService.signInWithGoogle(context),
                  onFacebookPressed: () => authentificationService.signInWithFacebook(context),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text("Vous avez déjà un compte ? Se connecter"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}