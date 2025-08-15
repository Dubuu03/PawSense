import 'package:flutter/material.dart';
import '../../models/time_slot.dart';

class TimeSlotItem extends StatelessWidget {
  final TimeSlot timeSlot;

  const TimeSlotItem({
    Key? key,
    required this.timeSlot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _buildTimeColumn(),
            SizedBox(width: 16),
            Expanded(
              child: _buildDetailsColumn(),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeSlot.startTime,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            timeSlot.endTime,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              timeSlot.type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6), // Blue color for type
              ),
            ),
            Text(
              timeSlot.appointmentText,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: timeSlot.utilizationPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: timeSlot.progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '${timeSlot.utilizationPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 20),
          onPressed: () {
            // TODO: Implement edit functionality
          },
          color: Color(0xFF6B7280),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 20),
          onPressed: () {
            // TODO: Implement delete functionality
          },
          color: Color(0xFF6B7280),
        ),
        IconButton(
          icon: Icon(Icons.more_horiz, size: 20),
          onPressed: () {
            // TODO: Implement more options
          },
          color: Color(0xFF6B7280),
        ),
      ],
    );
  }
}