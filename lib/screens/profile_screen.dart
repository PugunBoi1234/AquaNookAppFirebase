import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../widgets/avatar_display.dart';
import '../widgets/product_image.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSaving = false;
  late String _avatar;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  @override
  void initState() {
    super.initState();
    _avatar = widget.user.avatar;
    _listenToProfile(widget.user.id);
  }

  void _listenToProfile(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          final avatar = snapshot.data()?['avatar'] as String?;
          if (avatar != null && avatar != _avatar && mounted) {
            setState(() => _avatar = avatar);
          }
        });
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.avatar != widget.user.avatar) {
      _avatar = widget.user.avatar;
    }
    if (oldWidget.user.id != widget.user.id) {
      _listenToProfile(widget.user.id);
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3B42),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        // widget.user comes straight from AuthGate's live
                        // Firestore stream, so as soon as _saveAvatar()
                        // writes a change, this rebuilds with the new
                        // picture automatically — no local state needed.
                        child: ClipOval(
                          child: AvatarDisplay(avatar: _avatar, size: 42),
                        ),
                      ),
                      if (_isSaving)
                        const Positioned.fill(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF2EC4B6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.user.name,
                    style: GoogleFonts.baloo2(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B3B42),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF4C6B70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Choose a picture',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF123138),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                GestureDetector(
                  onTap: _isSaving ? null : _pickPhoto,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD6ECE9),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Color(0xFF146873),
                      size: 22,
                    ),
                  ),
                ),
                ...avatarChoices.map((avatar) {
                  final selected = avatar == _avatar;
                  return GestureDetector(
                    onTap: _isSaving ? null : () => _saveAvatar(avatar),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2EC4B6)
                              : const Color(0xFFE3F1EE),
                          width: selected ? 3 : 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(avatar, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              'Your Listings',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF123138),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFF2EC4B6),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Could not load your listings: ${snapshot.error}',
                    style: GoogleFonts.inter(color: const Color(0xFFFF8A5B)),
                  );
                }
                final products =
                    snapshot.data?.docs
                        .where(
                          (doc) =>
                              doc.data()['sellerId']?.toString() ==
                              widget.user.id,
                        )
                        .map((d) => Product.fromFirestore(d))
                        .toList() ??
                    [];
                if (products.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE3F1EE)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: Color(0xFF4C6B70),
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You haven't listed anything yet",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF123138),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the shop icon on the Shop tab to sell your first item.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF4C6B70),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: products.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3F1EE)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductImage(product: p, iconSize: 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.stock} in stock',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF4C6B70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${p.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF146873),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete product',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFFF8A5B),
                              size: 21,
                            ),
                            onPressed: () => _confirmDeleteProduct(p),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF8A5B),
                  side: const BorderSide(color: Color(0xFFFF8A5B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  'Log out',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from your listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A5B),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id.toString())
          .delete()
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Product deleted')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete product: $error')),
        );
      }
    }
  }

  Future<void> _saveAvatar(String avatar) async {
    if (avatar == _avatar) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'avatar': avatar})
          .timeout(const Duration(seconds: 15));
      // Also keep the "seller" copy in sync, in case this user sells things.
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.user.id)
          .set({'avatar': avatar}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
      if (mounted) setState(() => _avatar = avatar);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update your picture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);
      if (encoded.length > 900000) {
        throw StateError(
          'The selected photo is too large. Please choose a smaller photo.',
        );
      }
      await _saveAvatar('data:image/jpeg;base64,$encoded');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload your photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
