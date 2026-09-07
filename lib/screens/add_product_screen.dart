import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../models/user.dart';

class AddProductScreen extends StatefulWidget {
  final AppUser user;

  const AddProductScreen({super.key, required this.user});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _blurbController = TextEditingController();
  String _category = 'fish';
  bool _isSubmitting = false;
  Uint8List? _photoBytes;

  static const _categories = [
    {'value': 'fish', 'label': 'Fish'},
    {'value': 'decor', 'label': 'Tank Decor'},
    {'value': 'fish_food', 'label': 'Fish Food'},
    {'value': 'equipment', 'label': 'Equipment'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _blurbController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 82,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final uid = widget.user.id;

      // 1) Reserve the first free user-product id after the built-in catalog.
      final newId = await firestore
          .runTransaction<int>((transaction) async {
            final counterRef = firestore.collection('counters').doc('products');
            final counterSnap = await transaction.get(counterRef);
            final storedLastId =
                (counterSnap.data()?['lastId'] as num?)?.toInt() ??
                Product.localCatalogLastId;
            var nextId = Product.localCatalogLastId + 1;
            while ((await transaction.get(
              firestore.collection('products').doc(nextId.toString()),
            )).exists) {
              nextId++;
            }
            transaction.set(counterRef, {
              'lastId': nextId > storedLastId ? nextId : storedLastId,
            });
            return nextId;
          })
          .timeout(const Duration(seconds: 20));

      // 2) Store the optional photo inline so this works without Storage.
      String? imageUrl;
      if (_photoBytes != null) {
        final encoded = base64Encode(_photoBytes!);
        if (encoded.length > 900000) {
          throw StateError(
            'The selected image is too large. Please choose a smaller photo.',
          );
        }
        imageUrl = 'data:image/jpeg;base64,$encoded';
      }

      // 3) Make sure this user has a "seller" profile so their listing
      //    shows up correctly under "Sold by".
      await firestore
          .collection('sellers')
          .doc(uid)
          .set({
            'name': widget.user.name,
            'avatar': widget.user.avatar,
            'tagline': 'Community seller on AquaNook',
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));

      // 4) Write the product itself.
      final product = Product(
        id: newId,
        name: _nameController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text.trim()),
        rating: 0,
        stock: int.tryParse(_stockController.text.trim()) ?? 1,
        imageUrl: imageUrl,
        blurb: _blurbController.text.trim().isNotEmpty
            ? _blurbController.text.trim()
            : 'A community listing from ${widget.user.name}.',
        isNew: true,
        sellerId: uid,
      );
      await firestore
          .collection('products')
          .doc(newId.toString())
          .set(product.toFirestore())
          .timeout(const Duration(seconds: 15));

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Could not add your product: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        backgroundColor: const Color(0xFF0B3B42),
        foregroundColor: Colors.white,
        title: const Text('Sell a product'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Listed under your name — buyers can tap "Sold by" on your product to see everything you sell.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF4C6B70),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _label('Photo (optional)'),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD6ECE9)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photoBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: Color(0xFF4C6B70),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF4C6B70),
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_photoBytes!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _photoBytes = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Product name'),
              TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration('e.g. Homegrown Java Fern'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a product name'
                    : null,
              ),
              const SizedBox(height: 16),
              _label('Category'),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _fieldDecoration(null),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['value'],
                        child: Text(c['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Price (\$)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _fieldDecoration('0.00'),
                          validator: (v) {
                            final parsed = double.tryParse((v ?? '').trim());
                            if (parsed == null || parsed <= 0)
                              return 'Enter a valid price';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Stock'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('1'),
                          validator: (v) {
                            final parsed = int.tryParse((v ?? '').trim());
                            if (parsed == null || parsed < 1)
                              return 'Enter a valid amount';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Description (optional)'),
              TextFormField(
                controller: _blurbController,
                maxLines: 3,
                decoration: _fieldDecoration('What makes it worth a look?'),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EC4B6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                          'List it',
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
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4C6B70),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
