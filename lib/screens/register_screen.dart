import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user.dart';
import '../widgets/tank_illustration.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final email = _emailController.text.trim();
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );

      final uid = credential.user!.uid;
      const avatarChoicesLocal = avatarChoices;
      final randomAvatar =
          avatarChoicesLocal[uid.hashCode % avatarChoicesLocal.length];

      final newUser = AppUser(
        id: uid,
        name: _nameController.text.trim(),
        email: email,
        avatar: randomAvatar,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toFirestore());

      // createUserWithEmailAndPassword signs the new account in
      // automatically — sign back out so the person has to log in
      // themselves, as requested, instead of landing straight in the app.
      await FirebaseAuth.instance.signOut();

      if (mounted) Navigator.pop(context, email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _restoreMissingProfile();
        return;
      }
      _showError(_friendlyAuthError(e));
    } catch (e) {
      _showError('Could not create your account.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _restoreMissingProfile() async {
    try {
      final email = _emailController.text.trim();
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      final firebaseUser = credential.user!;
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid);
      final profile = await profileRef.get();

      if (profile.exists) {
        await FirebaseAuth.instance.signOut();
        _showError('This email is already registered. Please log in instead.');
        return;
      }

      final choices = avatarChoices;
      final avatar = choices[firebaseUser.uid.hashCode % choices.length];
      await profileRef.set(
        AppUser(
          id: firebaseUser.uid,
          name: _nameController.text.trim(),
          email: email,
          avatar: avatar,
        ).toFirestore(),
      );
      await FirebaseAuth.instance.signOut();

      if (mounted) Navigator.pop(context, email);
    } on FirebaseAuthException catch (e) {
      await FirebaseAuth.instance.signOut();
      _showError(_friendlyAuthError(e));
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      _showError('Could not restore this account. Please try logging in.');
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'weak-password':
        return 'Please use a stronger password (at least 6 characters).';
      case 'invalid-email':
        return 'That email address looks invalid.';
      default:
        return e.message ?? 'Could not create your account.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF8A5B),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF146873)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TankIllustration(height: 170),
                const SizedBox(height: 24),
                Text(
                  'Create your account',
                  style: GoogleFonts.baloo2(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B3B42),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join AquaNook to save favorites, order, and sell your own finds',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF4C6B70),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration(
                    'Full name',
                    Icons.person_outline_rounded,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration(
                    'Email',
                    Icons.mail_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration:
                      _fieldDecoration(
                        'Password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          color: const Color(0xFF4C6B70),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.length < 6)
                      return 'Use at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EC4B6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Create account',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4C6B70)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
