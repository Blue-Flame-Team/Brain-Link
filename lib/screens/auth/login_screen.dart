import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:brain_link/navigation/AppRoutes.dart';
import 'package:brain_link/helpers/shared_pref_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPassVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text,
        );

        await SharedPrefHelper.setLoggedIn(true);

        if (mounted) {
          _showSnackBar("Welcome Back!", Colors.green);
          Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
        }
      } on FirebaseAuthException catch (e) {
        String msg = "";
        switch (e.code) {
          case 'user-not-found':
            msg = "User doesn't exist";
            break;
          case 'wrong-password':
            msg = "Password is incorrect";
            break;
          case 'invalid-credential':
            msg = "Invalid email or password";
            break;
          case 'invalid-email':
            msg = "The email address is invalid";
            break;
          case 'user-disabled':
            msg = "This user account has been disabled";
            break;
          default:
            msg = "Login error: ${e.message}";
        }
        _showSnackBar(msg, Colors.red);
      } catch (e) {
        _showSnackBar("An unexpected error occurred", Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Text(
                  "Log In",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5E35B1),
                  ),
                ),
                const SizedBox(height: 80),
                TextFormField(
                  controller: _emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF5E35B1),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passController,
                  obscureText: !_isPassVisible,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF5E35B1),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPassVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _isPassVisible = !_isPassVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E35B1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an Account? "),
                    GestureDetector(
                      onTap: () async {
                        await _audioPlayer.play(
                          AssetSource('sounds/click.mp3'),
                        );
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.signup,
                        );
                      },
                      child: const Text(
                        "Signup here",
                        style: TextStyle(
                          color: Color(0xFF5E35B1),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
