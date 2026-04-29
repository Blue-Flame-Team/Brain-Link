import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:brain_link/model/user_model.dart';
import 'package:brain_link/services/auth_service.dart';
import 'package:brain_link/helpers/db_helper.dart';
import 'package:brain_link/helpers/shared_pref_helper.dart';
import 'package:brain_link/navigation/AppRoutes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _userFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPassVisible = false;
  bool _isConfirmVisible = false;
  bool _isTermsAccepted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _userFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_isTermsAccepted) {
      _showSnackBar("Please accept the terms and conditions", Colors.orange);
      return;
    }

    if (_formKey.currentState!.validate()) {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
      setState(() => _isLoading = true);
      try {
        final result = await AuthService().signUp(
          _emailController.text.trim(),
          _passController.text,
          _userController.text.trim(),
        );

        if (result != null) {
          UserModel user = UserModel(
            id: result.user!.uid,
            fullName: _userController.text.trim(),
            email: _emailController.text.trim(),
          );

          await DbHelper.saveUser(user);
          await SharedPrefHelper.setUser(user.email, "logged_in");

          _showSnackBar("Account Created Successfully!", Colors.green);
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed' || e.code == 'unknown') {
          _showSnackBar(
            "يجب توفر إنترنت لإنشاء حساب جديد، لا يمكن التسجيل Offline.",
            Colors.red,
          );
        } else {
          _showSnackBar(e.message ?? e.toString(), Colors.red);
        }
      } catch (e) {
        _showSnackBar(e.toString(), Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String msg, Color bgColor) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bgColor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundIcons(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "SignUp",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5E35B1),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildField(
                      _userController,
                      _userFocus,
                      "Full Name",
                      Icons.person_outline,
                      false,
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      _emailController,
                      _emailFocus,
                      "Email Address",
                      Icons.email_outlined,
                      false,
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      _passController,
                      _passFocus,
                      "Password",
                      Icons.lock_outline,
                      true,
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      _confirmController,
                      _confirmFocus,
                      "Confirm Password",
                      Icons.lock_reset,
                      true,
                    ),
                    const SizedBox(height: 15),
                    _buildTerms(),
                    const SizedBox(height: 25),
                    _buildSignupButton(),
                    const SizedBox(height: 15),
                    _buildLoginLink(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    FocusNode focus,
    String label,
    IconData icon,
    bool isPass,
  ) {
    bool visible = label.contains("Confirm")
        ? _isConfirmVisible
        : _isPassVisible;
    return TextFormField(
      controller: controller,
      focusNode: focus,
      autovalidateMode: focus.hasFocus
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      obscureText: isPass && !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5E35B1)),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() {
                  if (label.contains("Confirm"))
                    _isConfirmVisible = !_isConfirmVisible;
                  else
                    _isPassVisible = !_isPassVisible;
                }),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF5E35B1), width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "$label is required";
        if (label == "Full Name" && v.length < 3) return "Min 3 characters";
        if (label == "Email Address") {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(v))
            return "Enter a valid email (like nada@gmail.com)";
        }
        if (label == "Password" && v.length < 6) return "Min 6 characters";
        if (label == "Confirm Password" && v != _passController.text)
          return "Must match password";
        return null;
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Have an Account? "),
        GestureDetector(
          onTap: () async {
            await _audioPlayer.play(AssetSource('sounds/click.mp3'));
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
          child: const Text(
            "Sign in here",
            style: TextStyle(
              color: Color(0xFF5E35B1),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E35B1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Signup",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
      ),
    );
  }

  Widget _buildTerms() {
    return Row(
      children: [
        Checkbox(
          value: _isTermsAccepted,
          activeColor: const Color(0xFF5E35B1),
          onChanged: (v) => setState(() => _isTermsAccepted = v!),
        ),
        const Expanded(
          child: Text(
            "I accept BrainLink Terms & Privacy Policy",
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundIcons() {
    return Stack(
      children: const [
        Positioned(
          bottom: 150,
          left: 20,
          child: Opacity(
            opacity: 0.1,
            child: Icon(Icons.computer, size: 60, color: Color(0xFF5E35B1)),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 20,
          child: Opacity(
            opacity: 0.1,
            child: Icon(Icons.mouse, size: 50, color: Color(0xFF5E35B1)),
          ),
        ),
      ],
    );
  }
}
