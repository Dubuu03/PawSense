class SystemSettingsModel {
  final String defaultTimeZone;
  final String dateFormat;
  final Duration sessionTimeout;
  final bool twoFactorAuthEnabled;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final SystemHealthModel systemHealth;
  final List<SecurityEventModel> recentSecurityEvents;

  SystemSettingsModel({
    required this.defaultTimeZone,
    required this.dateFormat,
    required this.sessionTimeout,
    required this.twoFactorAuthEnabled,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.systemHealth,
    required this.recentSecurityEvents,
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      defaultTimeZone: json['defaultTimeZone'] ?? 'UTC-5 (Eastern)',
      dateFormat: json['dateFormat'] ?? 'MM/DD/YYYY',
      sessionTimeout: Duration(hours: json['sessionTimeoutHours'] ?? 8),
      twoFactorAuthEnabled: json['twoFactorAuthEnabled'] ?? false,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'Super Admin',
      systemHealth: SystemHealthModel.fromJson(json['systemHealth'] ?? {}),
      recentSecurityEvents: (json['recentSecurityEvents'] as List<dynamic>?)
              ?.map((e) => SecurityEventModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultTimeZone': defaultTimeZone,
      'dateFormat': dateFormat,
      'sessionTimeoutHours': sessionTimeout.inHours,
      'twoFactorAuthEnabled': twoFactorAuthEnabled,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'systemHealth': systemHealth.toJson(),
      'recentSecurityEvents':
          recentSecurityEvents.map((e) => e.toJson()).toList(),
    };
  }

  SystemSettingsModel copyWith({
    String? defaultTimeZone,
    String? dateFormat,
    Duration? sessionTimeout,
    bool? twoFactorAuthEnabled,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? role,
    SystemHealthModel? systemHealth,
    List<SecurityEventModel>? recentSecurityEvents,
  }) {
    return SystemSettingsModel(
      defaultTimeZone: defaultTimeZone ?? this.defaultTimeZone,
      dateFormat: dateFormat ?? this.dateFormat,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      twoFactorAuthEnabled: twoFactorAuthEnabled ?? this.twoFactorAuthEnabled,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      systemHealth: systemHealth ?? this.systemHealth,
      recentSecurityEvents: recentSecurityEvents ?? this.recentSecurityEvents,
    );
  }
}

class SystemHealthModel {
  final double systemUptime;
  final String systemUptimeLabel;
  final String databaseHealth;
  final String databaseStatus;
  final double storageUsage;
  final String storageDetails;
  final int activeSessions;
  final String activeSessionsLabel;

  SystemHealthModel({
    required this.systemUptime,
    required this.systemUptimeLabel,
    required this.databaseHealth,
    required this.databaseStatus,
    required this.storageUsage,
    required this.storageDetails,
    required this.activeSessions,
    required this.activeSessionsLabel,
  });

  factory SystemHealthModel.fromJson(Map<String, dynamic> json) {
    return SystemHealthModel(
      systemUptime: (json['systemUptime'] ?? 99.9).toDouble(),
      systemUptimeLabel: json['systemUptimeLabel'] ?? 'Last 30 days',
      databaseHealth: json['databaseHealth'] ?? 'Optimal',
      databaseStatus: json['databaseStatus'] ?? 'All connections stable',
      storageUsage: (json['storageUsage'] ?? 67.3).toDouble(),
      storageDetails: json['storageDetails'] ?? '2.1TB of 3TB used',
      activeSessions: json['activeSessions'] ?? 1247,
      activeSessionsLabel: json['activeSessionsLabel'] ?? 'Current concurrent users',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systemUptime': systemUptime,
      'systemUptimeLabel': systemUptimeLabel,
      'databaseHealth': databaseHealth,
      'databaseStatus': databaseStatus,
      'storageUsage': storageUsage,
      'storageDetails': storageDetails,
      'activeSessions': activeSessions,
      'activeSessionsLabel': activeSessionsLabel,
    };
  }
}

class SecurityEventModel {
  final String title;
  final String description;
  final DateTime timestamp;
  final SecurityEventType type;

  SecurityEventModel({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SecurityEventType.info,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }
}

enum SecurityEventType {
  success,
  warning,
  info,
  error,
}
