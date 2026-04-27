import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiServerConfigScreen extends StatefulWidget {
  const AiServerConfigScreen({super.key});

  @override
  State<AiServerConfigScreen> createState() => _AiServerConfigScreenState();
}

class _AiServerConfigScreenState extends State<AiServerConfigScreen> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  // This key will be used to store and retrieve the IP address.
  static const _serverIpKey = 'ai_server_ip';

  @override
  void initState() {
    super.initState();
    _loadServerIp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Loads the saved IP address from SharedPreferences and populates the text field.
  Future<void> _loadServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_serverIpKey);
    if (ip != null) {
      _controller.text = ip;
    }
    setState(() => _isLoading = false);
  }

  /// Saves the IP address from the text field to SharedPreferences.
  Future<void> _saveServerIp() async {
    if (_controller.text.isEmpty ||
        !Uri.tryParse(_controller.text.trim())!.isAbsolute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid URL (e.g., http://192.168.1.100:5000)')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, _controller.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Server address saved!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Server Config', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Icon(Icons.dns_rounded, size: 60, color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            'AI Server Address',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the full network address of your local Python server. This can be found by running `ipconfig` or `ifconfig` in your terminal.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Server URL (e.g., http://192.168.1.100:5000)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveServerIp,
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }
}
