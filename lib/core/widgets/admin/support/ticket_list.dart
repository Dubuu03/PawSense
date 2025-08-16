import 'package:flutter/material.dart';
import 'package:pawsense/core/models/ticket_status.dart';
import 'package:pawsense/core/widgets/admin/support/ticket_item.dart';
import '../../../models/support_ticket.dart';
import '../../../utils/constants.dart';

class TicketList extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedCategory;

  const TicketList({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final tickets = _getFilteredTickets();

    return ListView.separated(
      itemCount: tickets.length,
      separatorBuilder: (context, index) => SizedBox(height: kSpacingMedium),
      itemBuilder: (context, index) {
        return TicketItem(ticket: tickets[index]);
      },
    );
  }

  List<SupportTicket> _getFilteredTickets() {
    final allTickets = [
      SupportTicket(
        id: '1',
        title: 'Unable to book appointment for emergency visit',
        description: 'Hi, I\'m trying to book an emergency appointment for my dog Max who has been vomiting all morning. The app keeps showing "no available slots" but this is urgent. Please help!',
        submitterName: 'John Smith',
        submitterEmail: 'john.smith@email.com',
        category: 'Appointment',
        status: TicketStatus.open,
        createdAt: DateTime(2024, 1, 15, 14, 30),
        lastReply: DateTime(2024, 1, 15, 14, 45),
      ),
      SupportTicket(
        id: '2',
        title: 'App crashes when uploading pet photos',
        description: 'Every time I try to upload photos of my cat Luna\'s skin condition, the app crashes. I\'ve tried restarting my phone but the issue persists. Using iPhone 14 Pro with iOS 17.2.',
        submitterName: 'Sarah Johnson',
        submitterEmail: 'sarah.j@email.com',
        category: 'Technical',
        status: TicketStatus.inProgress,
        createdAt: DateTime(2024, 1, 15, 12, 15),
        lastReply: DateTime(2024, 1, 15, 13, 2),
      ),
      SupportTicket(
        id: '3',
        title: 'Question about vaccination schedule',
        description: 'Hi Dr. Johnson, I have a question about my puppy Charlie\'s vaccination schedule. He\'s 12 weeks old and has had his first round. When should I bring him in for the next set?',
        submitterName: 'Mike Wilson',
        submitterEmail: 'mike.w@email.com',
        category: 'General',
        status: TicketStatus.resolved,
        createdAt: DateTime(2024, 1, 14, 16, 20),
        lastReply: DateTime(2024, 1, 14, 18, 0),
      ),
      SupportTicket(
        id: '4',
        title: 'Billing inquiry about consultation fee',
        description: 'I was charged \$150 for yesterday\'s consultation but I thought the standard fee was \$75. Could you please review my billing?',
        submitterName: 'Emily Davis',
        submitterEmail: 'emily.d@email.com',
        category: 'Billing',
        status: TicketStatus.open,
        createdAt: DateTime(2024, 1, 15, 9, 45),
        lastReply: DateTime(2024, 1, 15, 9, 45),
      ),
    ];

    return allTickets.where((ticket) {
      final matchesSearch = searchQuery.isEmpty ||
          ticket.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          ticket.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = selectedStatus == 'All Status' ||
          ticket.status.displayName == selectedStatus;

      final matchesCategory = selectedCategory == 'All Categories' ||
          ticket.category == selectedCategory;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }
}