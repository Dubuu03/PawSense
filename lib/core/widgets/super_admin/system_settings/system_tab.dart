import 'package:flutter/material.dart';
import 'package:pawsense/core/models/system/system_settings_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class SystemTab extends StatefulWidget {
  final SystemSettingsModel settings;
  final Function(SystemSettingsModel) onSettingsChanged;

  const SystemTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> {
  String _selectedTimeZone = 'UTC-5 (Eastern)';
  String _selectedDateFormat = 'MM/DD/YYYY';
  String _selectedSessionTimeout = '8 hours';

  final List<String> _timeZones = [
    'UTC-12 (Baker Island)',
    'UTC-11 (American Samoa)',
    'UTC-10 (Hawaii)',
    'UTC-9 (Alaska)',
    'UTC-8 (Pacific)',
    'UTC-7 (Mountain)',
    'UTC-6 (Central)',
    'UTC-5 (Eastern)',
    'UTC-4 (Atlantic)',
    'UTC-3 (Argentina)',
    'UTC-2 (Mid-Atlantic)',
    'UTC-1 (Azores)',
    'UTC+0 (London)',
    'UTC+1 (Berlin)',
    'UTC+2 (Cairo)',
    'UTC+3 (Moscow)',
    'UTC+4 (Dubai)',
    'UTC+5 (Karachi)',
    'UTC+6 (Dhaka)',
    'UTC+7 (Bangkok)',
    'UTC+8 (Beijing)',
    'UTC+9 (Tokyo)',
    'UTC+10 (Sydney)',
    'UTC+11 (Magadan)',
    'UTC+12 (Auckland)',
  ];

  final List<String> _dateFormats = [
    'MM/DD/YYYY',
    'DD/MM/YYYY',
    'YYYY-MM-DD',
    'DD-MM-YYYY',
    'MM-DD-YYYY',
  ];

  final List<String> _sessionTimeouts = [
    '1 hour',
    '2 hours',
    '4 hours',
    '8 hours',
    '12 hours',
    '24 hours',
    'Never',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimeZone = widget.settings.defaultTimeZone;
    _selectedDateFormat = widget.settings.dateFormat;
    _selectedSessionTimeout = '${widget.settings.sessionTimeout.inHours} hours';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // System Configuration Section
        Text(
          'System Configuration',
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kSpacingLarge),
        
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                'Default Time Zone',
                _selectedTimeZone,
                _timeZones,
                (value) => setState(() {
                  _selectedTimeZone = value!;
                  _updateSettings(timeZone: value);
                }),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildDropdownField(
                'Date Format',
                _selectedDateFormat,
                _dateFormats,
                (value) => setState(() {
                  _selectedDateFormat = value!;
                  _updateSettings(dateFormat: value);
                }),
              ),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingLarge),
        
        _buildDropdownField(
          'Session Timeout',
          _selectedSessionTimeout,
          _sessionTimeouts,
          (value) => setState(() {
            _selectedSessionTimeout = value!;
            _updateSettings(sessionTimeout: value);
          }),
          width: 300,
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // System Health Section
        Text(
          'System Health',
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kSpacingLarge),
        
        Row(
          children: [
            Expanded(
              child: _buildHealthCard(
                'System Uptime',
                '${widget.settings.systemHealth.systemUptime}%',
                widget.settings.systemHealth.systemUptimeLabel,
                AppColors.success,
                Icons.trending_up,
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildHealthCard(
                'Database Health',
                widget.settings.systemHealth.databaseHealth,
                widget.settings.systemHealth.databaseStatus,
                AppColors.success,
                Icons.storage,
              ),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingLarge),
        
        Row(
          children: [
            Expanded(
              child: _buildHealthCard(
                'Storage Usage',
                '${widget.settings.systemHealth.storageUsage}%',
                widget.settings.systemHealth.storageDetails,
                widget.settings.systemHealth.storageUsage > 80 
                    ? AppColors.warning 
                    : AppColors.info,
                Icons.folder,
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildHealthCard(
                'Active Sessions',
                '${widget.settings.systemHealth.activeSessions}',
                widget.settings.systemHealth.activeSessionsLabel,
                AppColors.info,
                Icons.people,
              ),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // Save Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: Icon(Icons.save, size: kIconSizeMedium),
              label: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingLarge,
                  vertical: kSpacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: kSpacingSmall),
          DropdownButtonFormField<String>(
            initialValue: value,
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: kSpacingMedium,
                vertical: kSpacingMedium,
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    String title,
    String value,
    String subtitle,
    Color statusColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: statusColor,
                  size: kIconSizeMedium,
                ),
              ),
              SizedBox(width: kSpacingMedium),
              Expanded(
                child: Text(
                  title,
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingMedium),
          Text(
            value,
            style: kTextStyleLarge.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          SizedBox(height: kSpacingSmall / 2),
          Text(
            subtitle,
            style: kTextStyleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _updateSettings({
    String? timeZone,
    String? dateFormat,
    String? sessionTimeout,
  }) {
    Duration? timeout;
    if (sessionTimeout != null) {
      final hours = int.tryParse(sessionTimeout.split(' ').first) ?? 8;
      timeout = Duration(hours: hours);
    }

    widget.onSettingsChanged(
      widget.settings.copyWith(
        defaultTimeZone: timeZone,
        dateFormat: dateFormat,
        sessionTimeout: timeout,
      ),
    );
  }

  void _saveChanges() {
    // Add save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('System settings updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
