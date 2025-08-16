import 'package:flutter/material.dart';
import '../../../models/faq_item_model.dart';
import '../../../utils/constants.dart';
import 'faq_item.dart';

class FAQList extends StatefulWidget {
  const FAQList({super.key});

  @override
  _FAQListState createState() => _FAQListState();
}

class _FAQListState extends State<FAQList> {
  List<FAQItemModel> _faqItems = [];

  @override
  void initState() {
    super.initState();
    _initializeFAQItems();
  }

  void _initializeFAQItems() {
    _faqItems = [
      FAQItemModel(
        id: '1',
        question: 'How do I schedule an appointment?',
        answer: 'You can schedule an appointment through our mobile app or by calling our clinic directly. In the app, go to the "Appointments" section, select your preferred date and time, and choose the type of consultation you need.',
        category: 'Appointments',
        views: 120,
        helpfulVotes: 45,
      ),
      FAQItemModel(
        id: '2',
        question: 'What should I do if my pet has an emergency?',
        answer: 'For pet emergencies, call our emergency hotline immediately at (555) 911-PETS. If outside business hours, contact the nearest 24-hour animal hospital. Signs of emergency include difficulty breathing, severe bleeding, unconsciousness, or suspected poisoning.',
        category: 'Emergency Care',
        views: 95,
        helpfulVotes: 38,
      ),
      FAQItemModel(
        id: '3',
        question: 'How accurate is the AI disease detection?',
        answer: 'Our AI disease detection system has an accuracy rate of 92% for common skin conditions and 87% for general health assessments. However, it should be used as a preliminary screening tool and not as a replacement for professional veterinary diagnosis.',
        category: 'Technology',
        views: 180,
        helpfulVotes: 62,
      ),
      FAQItemModel(
        id: '4',
        question: 'What payment methods do you accept?',
        answer: 'We accept all major credit cards (Visa, MasterCard, American Express), debit cards, cash, and pet insurance. We also offer payment plans for major procedures. Payment is due at the time of service unless prior arrangements are made.',
        category: 'Billing',
        views: 75,
        helpfulVotes: 28,
      ),
      FAQItemModel(
        id: '5',
        question: 'How do I upload photos for disease detection?',
        answer: 'To upload photos for AI disease detection, open the app, go to "Health Check", select "Photo Analysis", and take clear, well-lit photos of the affected area. Make sure the image is in focus and shows the condition clearly for best results.',
        category: 'Technology',
        views: 140,
        helpfulVotes: 53,
      ),
      FAQItemModel(
        id: '6',
        question: 'What vaccinations does my pet need?',
        answer: 'Vaccination requirements depend on your pet\'s age, species, and lifestyle. Core vaccines for dogs include DHPP and rabies. For cats, core vaccines are FVRCP and rabies. Our veterinarians will create a personalized vaccination schedule based on your pet\'s needs.',
        category: 'Preventive Care',
        views: 110,
        helpfulVotes: 41,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _faqItems.length,
      separatorBuilder: (context, index) => SizedBox(height: kSpacingMedium),
      itemBuilder: (context, index) {
        return FAQItem(
          faqItem: _faqItems[index],
          onToggleExpanded: () {
            setState(() {
              _faqItems[index] = _faqItems[index].copyWith(
                isExpanded: !_faqItems[index].isExpanded,
              );
            });
          },
        );
      },
    );
  }
}