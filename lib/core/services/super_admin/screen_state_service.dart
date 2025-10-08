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
  String _appointmentDateSortOrder = 'desc'; // Default to newest first

  // Clinic Schedule State
  DateTime _scheduleSelectedDate = DateTime.now();
  String _scheduleSelectedDay = 'Monday';

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
  String get appointmentDateSortOrder => _appointmentDateSortOrder;

  void saveAppointmentState({
    required String searchQuery,
    required String selectedStatus,
    String? dateSortOrder,
  }) {
    _appointmentSearchQuery = searchQuery;
    _appointmentSelectedStatus = selectedStatus;
    if (dateSortOrder != null) {
      _appointmentDateSortOrder = dateSortOrder;
    }
    print('💾 Saved appointment management state: status="$selectedStatus", search="$searchQuery", sort="$_appointmentDateSortOrder"');
  }

  /// Reset appointment state to defaults
  void resetAppointmentState() {
    _appointmentSearchQuery = '';
    _appointmentSelectedStatus = 'All Status';
    _appointmentDateSortOrder = 'desc';
  }

  // Clinic Schedule Getters & Setters
  DateTime get scheduleSelectedDate => _scheduleSelectedDate;
  String get scheduleSelectedDay => _scheduleSelectedDay;

  void saveScheduleState({
    required DateTime selectedDate,
    required String selectedDay,
  }) {
    _scheduleSelectedDate = selectedDate;
    _scheduleSelectedDay = selectedDay;
    print('💾 Saved clinic schedule state: date=${selectedDate.toString().split(' ')[0]}, day="$selectedDay"');
  }

  /// Reset schedule state to defaults
  void resetScheduleState() {
    _scheduleSelectedDate = DateTime.now();
    _scheduleSelectedDay = 'Monday';
  }

  /// Reset all states
  void resetAllStates() {
    resetClinicState();
    resetUserState();
    resetAppointmentState();
    resetScheduleState();
  }
}
