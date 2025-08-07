import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'view/chat_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verificar si Firebase ya está inicializado antes de intentar inicializarlo
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Si Firebase ya está inicializado, no hacer nada
    if (!e.toString().contains('duplicate-app')) {
      // Si es otro error, relanzarlo
      rethrow;
    }
  }

  // Configurar Firebase Realtime Database para persistencia offline
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (e) {
    // La persistencia ya puede estar habilitada, continuar silenciosamente
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Realtime',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: const ChatView(chatId: 'Amigos'),
    );
  }
}
