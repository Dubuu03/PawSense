import 'package:flutter/material.dart';
import 'stats_card.dart';

class StatsCards extends StatelessWidget {
  final List<Map<String, dynamic>> statsList;

  const StatsCards({super.key, required this.statsList});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(statsList.length, (index) {
        final stat = statsList[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < statsList.length - 1 ? 16 : 0),
            child: StatsCard(
              title: stat['title'],
              value: stat['value'],
              change: stat['change'],
              changeColor: stat['changeColor'],
              icon: stat['icon'],
              iconColor: stat['iconColor'],
            ),
          ),
        );
      }),
    );
  }
}
