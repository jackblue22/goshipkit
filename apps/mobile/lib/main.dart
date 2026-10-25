import 'package:flutter/material.dart';

void main() => runApp(const GoShipKitApp());

class GoShipKitApp extends StatelessWidget {
  const GoShipKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoShipKit',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF176B5B)),
      home: const Scaffold(
        body: SafeArea(
          child: Center(child: Text('GoShipKit mobile')),
        ),
      ),
    );
  }
}
