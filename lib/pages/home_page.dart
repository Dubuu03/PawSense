import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home', style: Theme.of(context).textTheme.titleLarge)),
      body: Center(
        child: Text(
          'Welcome to the Home Page!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
