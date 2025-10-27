import 'package:flutter/material.dart';

class AbsenceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absences List')),
      body: const Center(
        child: Text(
          'Welcome to the Absences List!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}