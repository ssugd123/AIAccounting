import 'package:flutter/material.dart';

void main() {
  runApp(const AIAccountingApp());
}

class AIAccountingApp extends StatelessWidget {
  const AIAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Accounting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Accounting'),
      ),
      body: const Center(
        child: Text('Personal Expense Tracker'),
      ),
    );
  }
}
