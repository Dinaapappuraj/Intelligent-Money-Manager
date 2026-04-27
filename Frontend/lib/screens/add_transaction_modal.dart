import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import 'add_expense_screen.dart';
import 'review_scan_screen.dart';

class AddTransactionModal extends StatelessWidget {
  const AddTransactionModal({super.key});

  Future<void> _pickImageAndNavigate(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && context.mounted) {
        Navigator.of(context).pop();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) {
              return MultiProvider(
                providers: [
                  Provider.value(
                    value: Provider.of<AiService>(context, listen: false),
                  ),
                  Provider.value(
                    value: Provider.of<FirestoreService>(context, listen: false),
                  ),
                ],
                child: ReviewScanScreen(imagePath: pickedFile.path),
              );
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Image picking cancelled: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add a New Transaction', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildOptionTile(
            context,
            icon: Icons.edit_note_rounded,
            title: 'Manual Entry',
            subtitle: 'Enter details by hand',
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) {
                  return Provider.value(
                    value: firestoreService,
                    child: const AddExpenseScreen(),
                  );
                },
              );
            },
          ),
          const Divider(),
          _buildOptionTile(
            context,
            icon: Icons.camera_alt_outlined,
            title: 'Scan Receipt',
            subtitle: 'Use your camera to capture a bill',
            onTap: () => _pickImageAndNavigate(context, ImageSource.camera),
          ),
          const Divider(),
          _buildOptionTile(
            context,
            icon: Icons.upload_file_outlined,
            title: 'Upload Image',
            subtitle: 'Pick a receipt from your gallery',
            onTap: () => _pickImageAndNavigate(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins()),
      onTap: onTap,
    );
  }
}

