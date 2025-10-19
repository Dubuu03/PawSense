// Example: How to use Legal Documents in Mobile App

import 'package:flutter/material.dart';
import 'package:pawsense/core/models/system/legal_document_model.dart';
import 'package:pawsense/pages/mobile/auth/legal_document_modal.dart';
import 'package:pawsense/pages/mobile/legal_documents_page.dart';

// ===================================
// EXAMPLE 1: Sign-Up Flow
// Required acceptance during registration
// ===================================
void showTermsForSignUp(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must accept or cancel
    builder: (context) => const LegalDocumentModal(
      documentType: DocumentType.termsAndConditions,
      requireAcceptance: true, // Shows checkbox and enforces scroll
    ),
  );

  if (agreed == true) {
    // User accepted, proceed with registration
    print('User accepted terms');
  } else {
    // User declined, handle accordingly
    print('User declined terms');
  }
}

// ===================================
// EXAMPLE 2: View Only (No Acceptance)
// For settings or help sections
// ===================================
void showPrivacyPolicy(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LegalDocumentModal(
      documentType: DocumentType.privacyPolicy,
      requireAcceptance: false, // Just view, no acceptance needed
    ),
  );
}

// ===================================
// EXAMPLE 3: Legal Documents Page
// Dedicated page with all documents
// ===================================
void navigateToLegalDocuments(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const LegalDocumentsPage(),
    ),
  );
}

// ===================================
// EXAMPLE 4: In Settings Menu
// Add to your settings list
// ===================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // ... other settings items
          
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms and Conditions'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const LegalDocumentModal(
                  documentType: DocumentType.termsAndConditions,
                  requireAcceptance: false,
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const LegalDocumentModal(
                  documentType: DocumentType.privacyPolicy,
                  requireAcceptance: false,
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('All Legal Documents'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => navigateToLegalDocuments(context),
          ),
        ],
      ),
    );
  }
}

// ===================================
// EXAMPLE 5: Before Critical Actions
// Show terms before important operations
// ===================================
void beforeDataDeletion(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => const LegalDocumentModal(
      documentType: DocumentType.userAgreement,
      requireAcceptance: true,
    ),
  );

  if (agreed == true) {
    // Proceed with deletion
    deleteUserData();
  }
}

void deleteUserData() {
  // Implementation
}

// ===================================
// EXAMPLE 6: Custom Document Type
// If you add more document types
// ===================================
void showCookiePolicy(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LegalDocumentModal(
      documentType: DocumentType.other, // Use 'other' for custom types
      requireAcceptance: false,
    ),
  );
}

// ===================================
// EXAMPLE 7: In Onboarding Flow
// Show during app first run
// ===================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _completeOnboarding() async {
    // Show terms at the end of onboarding
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LegalDocumentModal(
        documentType: DocumentType.termsAndConditions,
        requireAcceptance: true,
      ),
    );

    if (agreed == true) {
      // Mark onboarding complete
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _completeOnboarding,
          child: const Text('Get Started'),
        ),
      ),
    );
  }
}

// ===================================
// EXAMPLE 8: Quick Access Button
// Floating action or help button
// ===================================
Widget buildHelpButton(BuildContext context) {
  return FloatingActionButton(
    onPressed: () {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help Center'),
                onTap: () {
                  // Navigate to help
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Legal Documents'),
                onTap: () {
                  Navigator.pop(context);
                  navigateToLegalDocuments(context);
                },
              ),
            ],
          ),
        ),
      );
    },
    child: const Icon(Icons.help),
  );
}
