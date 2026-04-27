import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, AuthService authService) {
    final nameController =
    TextEditingController(text: authService.currentUser?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Display Name', style: GoogleFonts.poppins()),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'New Name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  authService.updateDisplayName(
                      nameController.text.trim());
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // ✅ SAFE INITIAL LOGIC (FIXED)
    String initial = 'B';
    if (user?.displayName != null &&
        user!.displayName!.trim().isNotEmpty) {
      initial = user.displayName!.trim()[0].toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              (user?.displayName != null &&
                  user!.displayName!.trim().isNotEmpty)
                  ? user.displayName!
                  : 'Buddy',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? 'buddy@mail.co',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildProfileOption(
            context,
            icon: Icons.person_outline,
            title: 'Edit Name',
            onTap: () => _showEditNameDialog(context, authService),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              authService.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor, // ✅ same color
              foregroundColor: Colors.white, // ✅ white text
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing:
      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}