/// Service to persist screen state across navigation
/// Ensures UI state (current page, filters, search query) is preserved when switching tabs
class ScreenStateService {
  static final ScreenStateService _instance = ScreenStateService._internal();
  factory ScreenStateService() => _instance;
  ScreenStateService._internal();

  // Clinic Management State
  int _clinicCurrentPage = 1;
  String _clinicSearchQuery = '';
  String _clinicSelectedStatus = '';

  // User Management State
  int _userCurrentPage = 1;
  String _userSearchQuery = '';
  String _userSelectedRole = 'All Roles';
  String _userSelectedStatus = 'All Status';

  // Appointment Management State
  String _appointmentSearchQuery = '';
  String _appointmentSelectedStatus = 'All Status';

  // Clinic Management Getters & Setters
  int get clinicCurrentPage => _clinicCurrentPage;
  String get clinicSearchQuery => _clinicSearchQuery;
  String get clinicSelectedStatus => _clinicSelectedStatus;

  void saveClinicState({
    required int currentPage,
    required String searchQuery,
    required String selectedStatus,
  }) {
    _clinicCurrentPage = currentPage;
    _clinicSearchQuery = searchQuery;
    _clinicSelectedStatus = selectedStatus;
    print('💾 Saved clinic management state: page=$currentPage, status="$selectedStatus", search="$searchQuery"');
  }

  // User Management Getters & Setters
  int get userCurrentPage => _userCurrentPage;
  String get userSearchQuery => _userSearchQuery;
  String get userSelectedRole => _userSelectedRole;
  String get userSelectedStatus => _userSelectedStatus;

  void saveUserState({
    required int currentPage,
    required String searchQuery,
    required String selectedRole,
    required String selectedStatus,
  }) {
    _userCurrentPage = currentPage;
    _userSearchQuery = searchQuery;
    _userSelectedRole = selectedRole;
    _userSelectedStatus = selectedStatus;
    print('💾 Saved user management state: page=$currentPage, role="$selectedRole", status="$selectedStatus", search="$searchQuery"');
  }

  /// Reset clinic state to defaults
  void resetClinicState() {
    _clinicCurrentPage = 1;
    _clinicSearchQuery = '';
    _clinicSelectedStatus = '';
  }

  /// Reset user state to defaults
  void resetUserState() {
    _userCurrentPage = 1;
    _userSearchQuery = '';
    _userSelectedRole = 'All Roles';
    _userSelectedStatus = 'All Status';
  }

  // Appointment Management Getters & Setters
  String get appointmentSearchQuery => _appointmentSearchQuery;
  String get appointmentSelectedStatus => _appointmentSelectedStatus;

  void saveAppointmentState({
    required String searchQuery,
    required String selectedStatus,
  }) {
    _appointmentSearchQuery = searchQuery;
    _appointmentSelectedStatus = selectedStatus;
    print('💾 Saved appointment management state: status="$selectedStatus", search="$searchQuery"');
  }

  /// Reset appointment state to defaults
  void resetAppointmentState() {
    _appointmentSearchQuery = '';
    _appointmentSelectedStatus = 'All Status';
  }

  /// Reset all states
  void resetAllStates() {
    resetClinicState();
    resetUserState();
    resetAppointmentState();
  }
}
