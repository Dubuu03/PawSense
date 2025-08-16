import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/admin/support/faq_list.dart';
import 'package:pawsense/core/widgets/admin/support/support_filters.dart';
import 'package:pawsense/core/widgets/admin/support/support_header.dart';
import 'package:pawsense/core/widgets/admin/support/support_tabs.dart';
import 'package:pawsense/core/widgets/admin/support/ticket_list.dart';
import '../../../core/utils/app_colors.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  _SupportCenterScreenState createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All Status';
  String _selectedCategory = 'All Categories';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SupportHeader(),
            SizedBox(height: kSpacingLarge),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(kSpacingLarge),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
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
                    SupportTabs(
                      tabController: _tabController,
                      onTabChanged: (index) {
                        setState(() {});
                      },
                    ),
                    SizedBox(height: kSpacingLarge),
                    if (_tabController.index == 0) ...[
                      SupportFilters(
                        searchQuery: _searchQuery,
                        selectedStatus: _selectedStatus,
                        selectedCategory: _selectedCategory,
                        onSearchChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                        onStatusChanged: (status) {
                          setState(() {
                            _selectedStatus = status;
                          });
                        },
                        onCategoryChanged: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                      SizedBox(height: kSpacingLarge),
                    ],
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          TicketList(
                            searchQuery: _searchQuery,
                            selectedStatus: _selectedStatus,
                            selectedCategory: _selectedCategory,
                          ),
                          FAQList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}