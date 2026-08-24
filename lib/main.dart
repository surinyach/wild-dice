import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAuthService().ensureAnonymousUser();

  // Ensure the Firestore client is online and ready for synchronized game data.
  await FirebaseFirestore.instance.enableNetwork();

  runApp(const App());
}
