import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          // If user is logged in, provide all necessary services for the main app
          return MultiProvider(
            providers: [
              Provider<EncryptionService>(create: (_) => EncryptionService()),
              Provider<AiService>(create: (_) => AiService()),
              // FirestoreService depends on the user's ID and the EncryptionService
              ProxyProvider<EncryptionService, FirestoreService>(
                update: (context, encryptionService, _) => FirestoreService(
                  userId: user.uid,
                  encryptionService: encryptionService,
                ),
              ),
            ],
            child: MainScreen(), // Use non-const because of the GlobalKey
          );
        }
        // While waiting for auth state, show a loading indicator
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

