import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/encryption_service.dart';
import 'profile_screen.dart';
import 'recurring_transactions_screen.dart';
import 'change_password_screen.dart';
import 'encryption_key_screen.dart';
import 'ai_server_config_screen.dart'; // --- ADDED THIS IMPORT ---

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.sync_rounded,
            title: 'Recurring Transactions',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return Provider.value(
                  value: Provider.of<FirestoreService>(context, listen: false),
                  child: const RecurringTransactionsScreen(),
                );
              }));
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Security & Advanced'),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.vpn_key_outlined,
            title: 'Encryption Key',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return Provider.value(
                  value: Provider.of<EncryptionService>(context, listen: false),
                  child: const EncryptionKeyScreen(),
                );
              }));
            },
          ),
          // --- ADDED THIS TILE ---
          _buildSettingsTile(
            context,
            icon: Icons.dns_rounded,
            title: 'AI Server Configuration',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AiServerConfigScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
