import 'package:flutter/material.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class MessagingTestPage extends StatefulWidget {
  const MessagingTestPage({super.key});

  @override
  State<MessagingTestPage> createState() => _MessagingTestPageState();
}

class _MessagingTestPageState extends State<MessagingTestPage> {
  String _testResult = 'Testing...';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    try {
      // Test 1: Check if user is authenticated
      final user = await AuthGuard.getCurrentUser();
      if (user == null) {
        setState(() {
          _testResult = 'Test Failed: No authenticated user found';
        });
        return;
      }

      // Test 2: Try to get approved clinics
      final clinics = await MessagingService.getApprovedClinics();
      print('Found ${clinics.length} approved clinics');

      // Test 3: Try to listen to conversations stream
      final stream = MessagingService.getUserConversations();
      final streamSubscription = stream.listen(
        (conversations) {
          print('Received ${conversations.length} conversations');
          setState(() {
            _testResult = '''
Tests Completed Successfully:
✅ User authenticated: ${user.firstName} ${user.lastName}
✅ Found ${clinics.length} approved clinics
✅ Conversations stream working: ${conversations.length} conversations
            ''';
          });
        },
        onError: (error) {
          print('Stream error: $error');
          setState(() {
            _testResult = '''
Tests Results:
✅ User authenticated: ${user.firstName} ${user.lastName}
✅ Found ${clinics.length} approved clinics
❌ Conversations stream error: $error
            ''';
          });
        },
      );

      // Clean up after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        streamSubscription.cancel();
      });

    } catch (e) {
      setState(() {
        _testResult = 'Test Failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messaging System Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messaging System Diagnostic',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(_testResult),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runTests,
              child: const Text('Run Tests Again'),
            ),
          ],
        ),
      ),
    );
  }
}