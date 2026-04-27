import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../services/encryption_service.dart'; // THE CHANGE

class EncryptionKeyScreen extends StatefulWidget {
  const EncryptionKeyScreen({super.key});

  @override
  State<EncryptionKeyScreen> createState() => _EncryptionKeyScreenState();
}

class _EncryptionKeyScreenState extends State<EncryptionKeyScreen> {
  // State logic is identical to the mock
  final _keyController = TextEditingController();
  bool _isKeySet = false;
  bool _isLoading = true;
  bool _isKeyVisible = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isDeviceSupported = false; // To track if device has security features

  @override
  void initState() {
    super.initState();
    _checkDeviceSupport();
    _loadKey();
  }

  // --- THE FIX #1: Check for device support upfront ---
  Future<void> _checkDeviceSupport() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      setState(() => _isDeviceSupported = isSupported);
    } on PlatformException catch (e) {
      print("Error checking device support: $e");
    }
  }

  Future<void> _loadKey() async {
    // THE CHANGE: Use the real EncryptionService
    final encryptionService = Provider.of<EncryptionService>(context, listen: false);
    final key = await encryptionService.getSecretKey();
    if (key != null) {
      setState(() {
        _keyController.text = key;
        _isKeySet = true;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveKey() async {
    if (_keyController.text.length != 32) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Secret key must be exactly 32 characters long.')),
      );
      return;
    }
    // THE CHANGE: Use the real EncryptionService
    final encryptionService = Provider.of<EncryptionService>(context, listen: false);
    await encryptionService.setSecretKey(_keyController.text);
    setState(() {
      _isKeySet = true;
      _isKeyVisible = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secret key saved securely!')),
    );
  }

  // --- THE FIX #2: The updated, smarter toggle logic ---
  Future<void> _toggleKeyVisibility() async {
    if (_isKeyVisible) {
      setState(() => _isKeyVisible = false);
      return;
    }

    // First, check if the device has a lock screen.
    if (!_isDeviceSupported) {
      _showSetupDialog();
      return;
    }

    // If it does, proceed with authentication.
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to reveal your secret key',
      );
      if (didAuthenticate) {
        setState(() => _isKeyVisible = true);
      }
    } on PlatformException catch (e) {
      print("Authentication error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Please try again.')),
      );
    }
  }

  // --- THE FIX #3: A helpful dialog to guide the user ---
  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Security Required', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'To protect your secret key, you need to set up a PIN, pattern, or fingerprint on your device first.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encryption Key', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Icon(Icons.vpn_key_rounded, size: 60, color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            'Your Secret Key',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This key encrypts all your financial data. It is stored ONLY on your device. If you lose it, your data cannot be recovered.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _keyController,
            obscureText: !_isKeyVisible,
            decoration: InputDecoration(
              labelText: '32-Character Secret Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_isKeyVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: _toggleKeyVisibility,
              ),
            ),
            maxLength: 32,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveKey,
            child: const Text('Save Key'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _keyController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Key copied to clipboard!')),
              );
            },
          ),
          const SizedBox(height: 30),
          _buildWarningBox(),
        ],
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRITICAL WARNING',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• We NEVER save this key on our servers.\n• If you reinstall the app or get a new phone, you MUST enter this exact key to decrypt your data.\n• Store it safely in a password manager.',
            style: GoogleFonts.poppins(color: Colors.red.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}

