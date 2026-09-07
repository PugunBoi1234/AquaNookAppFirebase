import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class PhoneContainerWrapper extends StatelessWidget {
  const PhoneContainerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3B42),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F5),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF0B3B42), width: 6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 45,
                spreadRadius: 2,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const AuthGate(),
        ),
      ),
    );
  }
}

/// Decides whether to show the Login/Register flow or the main app.
///
/// Both layers here are LIVE Firebase streams:
///  - `authStateChanges()` fires whenever someone signs in/out (anywhere
///    in the app — login, register, or logout in Profile).
///  - the Firestore `users/{uid}` snapshot stream fires whenever that
///    user's profile document changes (e.g. picking a new avatar).
///
/// Because both are streams, there's no more need to manually pass an
/// `onUserUpdated` or `onLogout` callback down through every screen —
/// any screen can just call `FirebaseAuth.instance.signOut()` or write to
/// Firestore directly, and this widget rebuilds the rest of the app
/// automatically.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _missingProfileHandled = false;
  String? _authMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          _missingProfileHandled = false;
          return LoginScreen(initialMessage: _authMessage);
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            if (!profileSnapshot.hasData ||
                profileSnapshot.data?.data() == null) {
              if (!_missingProfileHandled) {
                _missingProfileHandled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _restoreMissingProfile(firebaseUser);
                });
              }
              return const _LoadingScreen();
            }

            _authMessage = null;
            final user = AppUser.fromFirestore(
              firebaseUser.uid,
              profileSnapshot.data!.data()!,
            );
            return MainScreen(user: user);
          },
        );
      },
    );
  }

  Future<void> _restoreMissingProfile(User firebaseUser) async {
    try {
      final email = firebaseUser.email ?? '';
      final fallbackName = email.contains('@')
          ? email.split('@').first
          : 'AquaNook user';
      final avatar =
          avatarChoices[firebaseUser.uid.hashCode.abs() % avatarChoices.length];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
            'name': firebaseUser.displayName?.trim().isNotEmpty == true
                ? firebaseUser.displayName
                : fallbackName,
            'email': email,
            'avatar': avatar,
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (mounted) {
        setState(() {
          _authMessage = 'Invalid email or password';
        });
      }
      await FirebaseAuth.instance.signOut();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAF7F5),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2EC4B6))),
    );
  }
}
