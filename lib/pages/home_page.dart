import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';
import '../models/user_model.dart';
import '../services/user_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final UserServices _userServices = UserServices();
  UserModel? _userModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userServices.getUserByUid(user.uid);
      setState(() {
        _userModel = userModel;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: _loading
    ? const CircularProgressIndicator()
    : _userModel != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Home Page,',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _userModel!.username,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Home Page!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),

      ),
    );
  }
}
