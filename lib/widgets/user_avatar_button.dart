import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/profile_screen.dart';
import 'avatar_display.dart';

/// Small circular avatar shown top-right on every screen. Tapping it opens
/// the profile screen where the user can change their picture or log out.
///
/// Only needs `user` now — profile edits and logout write straight to
/// Firebase, and AuthGate's live streams push the result back down to
/// every screen automatically.
class UserAvatarButton extends StatelessWidget {
  final AppUser user;
  final Color background;

  const UserAvatarButton({
    super.key,
    required this.user,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        alignment: Alignment.center,
        child: ClipOval(child: AvatarDisplay(avatar: user.avatar, size: 17)),
      ),
    );
  }
}
