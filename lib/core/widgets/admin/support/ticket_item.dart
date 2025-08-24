import 'package:flutter/material.dart';
import '../../../models/support_ticket.dart';
import '../../../models/ticket_status.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import 'ticket_details_modal.dart';

class TicketItem extends StatelessWidget {
  final SupportTicket ticket;

  const TicketItem({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: kSpacingMedium),
          _buildDescription(),
          SizedBox(height: kSpacingMedium),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: kSpacingSmall),
        Expanded(
          child: Text(
            ticket.title,
            style: TextStyle(
              fontSize: kFontSizeRegular,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _buildStatusBadge(),
        SizedBox(width: kSpacingMedium),
        _buildCategoryBadge(),
        SizedBox(width: kSpacingMedium),
        IconButton(
          onPressed: () {},
          icon: Icon(
            ticket.isFavorited ? Icons.star : Icons.star_border,
            color: ticket.isFavorited ? Colors.amber : AppColors.textTertiary,
            size: 20,
          ),
        ),
        SizedBox(width: kSpacingSmall),
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => TicketDetailsModal(
                  ticketData: {
                    'title': ticket.title,
                    'status': ticket.status.displayName,
                    'category': ticket.category,
                    'userName': ticket.submitterName,
                    'userEmail': ticket.submitterEmail,
                    'messages': [
                      {
                        'sender': 'user',
                        'text': ticket.description,
                        'timestamp': ticket.formattedCreatedAt,
                      },
                      if (ticket.status != TicketStatus.open)
                        {
                          'sender': 'admin',
                          'text': 'I understand this is urgent. Let me check our emergency slots and get back to you within 15 minutes.',
                          'timestamp': ticket.formattedLastReply,
                        },
                    ],
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              ),
            ),
            child: Text(
              'View Details',
              style: TextStyle(fontSize: kFontSizeSmall),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      ticket.description,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 16, color: AppColors.textTertiary),
        SizedBox(width: 4),
        Text(
          ticket.submitterName,
          style: TextStyle(
            fontSize: kFontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Icon(Icons.email_outlined, size: 16, color: AppColors.textTertiary),
        SizedBox(width: 4),
        Text(
          ticket.submitterEmail,
          style: TextStyle(
            fontSize: kFontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
        SizedBox(width: 4),
        Text(
          ticket.formattedCreatedAt,
          style: TextStyle(
            fontSize: kFontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        Spacer(),
        Text(
          'Last reply: ${ticket.formattedLastReply}',
          style: TextStyle(
            fontSize: kFontSizeSmall,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ticket.status.displayName,
        style: TextStyle(
          fontSize: kFontSizeSmall,
          color: _getStatusColor(),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ticket.category,
        style: TextStyle(
          fontSize: kFontSizeSmall,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (ticket.status) {
      case TicketStatus.open:
        return AppColors.statusOpen;
      case TicketStatus.inProgress:
        return AppColors.statusInProgress;
      case TicketStatus.resolved:
        return AppColors.statusResolved;
    }
  }

  Color _getStatusBackgroundColor() {
    switch (ticket.status) {
      case TicketStatus.open:
        return AppColors.statusOpenBg;
      case TicketStatus.inProgress:
        return AppColors.statusInProgressBg;
      case TicketStatus.resolved:
        return AppColors.statusResolvedBg;
    }
  }
}