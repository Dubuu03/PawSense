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
  int _appointmentCurrentPage = 1;
  String _appointmentSearchQuery = '';
  String _appointmentSelectedStatus = 'All Status';
  String _appointmentDateSortOrder = 'desc'; // Default to newest first
  DateTime? _appointmentStartDate;
  DateTime? _appointmentEndDate;
  bool? _appointmentFollowUpFilter; // null = all, true = needs follow-up, false = no follow-up
  String? _appointmentSelectedPetType;
  String? _appointmentSelectedBreed;

  // Clinic Schedule State
  DateTime _scheduleSelectedDate = DateTime.now();
  String _scheduleSelectedDay = 'Monday';

  // Breed Management State
  int _breedCurrentPage = 1;
  String _breedSearchQuery = '';
  String _breedSelectedSpecies = 'all';
  String _breedSelectedStatus = 'all';
  String _breedSelectedSort = 'name_asc';

  // Disease Management State
  int _diseaseCurrentPage = 1;
  String _diseaseSearchQuery = '';
  String? _diseaseDetectionFilter;
  List<String> _diseaseSpeciesFilter = [];
  String? _diseaseSeverityFilter;
  List<String> _diseaseCategoriesFilter = [];
  bool? _diseaseContagiousFilter;
  String _diseaseSortBy = 'name_asc';

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
  int get appointmentCurrentPage => _appointmentCurrentPage;
  String get appointmentSearchQuery => _appointmentSearchQuery;
  String get appointmentSelectedStatus => _appointmentSelectedStatus;
  String get appointmentDateSortOrder => _appointmentDateSortOrder;
  DateTime? get appointmentStartDate => _appointmentStartDate;
  DateTime? get appointmentEndDate => _appointmentEndDate;
  bool? get appointmentFollowUpFilter => _appointmentFollowUpFilter;
  String? get appointmentSelectedPetType => _appointmentSelectedPetType;
  String? get appointmentSelectedBreed => _appointmentSelectedBreed;

  void saveAppointmentState({
    int? currentPage,
    required String searchQuery,
    required String selectedStatus,
    String? dateSortOrder,
    DateTime? startDate,
    DateTime? endDate,
    bool? followUpFilter,
    String? selectedPetType,
    String? selectedBreed,
  }) {
    if (currentPage != null) {
      _appointmentCurrentPage = currentPage;
    }
    _appointmentSearchQuery = searchQuery;
    _appointmentSelectedStatus = selectedStatus;
    if (dateSortOrder != null) {
      _appointmentDateSortOrder = dateSortOrder;
    }
    _appointmentStartDate = startDate;
    _appointmentEndDate = endDate;
    _appointmentFollowUpFilter = followUpFilter;
    _appointmentSelectedPetType = selectedPetType;
    _appointmentSelectedBreed = selectedBreed;
    print('💾 Saved appointment management state: page=$_appointmentCurrentPage, status="$selectedStatus", search="$searchQuery", sort="$_appointmentDateSortOrder", dates="${startDate?.toString().split(' ')[0]} to ${endDate?.toString().split(' ')[0]}", followUp=$followUpFilter, petType=$selectedPetType, breed=$selectedBreed');
  }

  /// Reset appointment state to defaults
  void resetAppointmentState() {
    _appointmentCurrentPage = 1;
    _appointmentSearchQuery = '';
    _appointmentSelectedStatus = 'All Status';
    _appointmentDateSortOrder = 'desc';
    _appointmentStartDate = null;
    _appointmentEndDate = null;
    _appointmentFollowUpFilter = null;
    _appointmentSelectedPetType = null;
    _appointmentSelectedBreed = null;
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

  // Breed Management Getters & Setters
  int get breedCurrentPage => _breedCurrentPage;
  String get breedSearchQuery => _breedSearchQuery;
  String get breedSelectedSpecies => _breedSelectedSpecies;
  String get breedSelectedStatus => _breedSelectedStatus;
  String get breedSelectedSort => _breedSelectedSort;

  void saveBreedState({
    required int currentPage,
    required String searchQuery,
    required String selectedSpecies,
    required String selectedStatus,
    required String selectedSort,
  }) {
    _breedCurrentPage = currentPage;
    _breedSearchQuery = searchQuery;
    _breedSelectedSpecies = selectedSpecies;
    _breedSelectedStatus = selectedStatus;
    _breedSelectedSort = selectedSort;
    print('💾 Saved breed management state: page=$currentPage, species="$selectedSpecies", status="$selectedStatus", sort="$selectedSort", search="$searchQuery"');
  }

  /// Reset breed state to defaults
  void resetBreedState() {
    _breedCurrentPage = 1;
    _breedSearchQuery = '';
    _breedSelectedSpecies = 'all';
    _breedSelectedStatus = 'all';
    _breedSelectedSort = 'name_asc';
  }

  // Disease Management Getters & Setters
  int get diseaseCurrentPage => _diseaseCurrentPage;
  String get diseaseSearchQuery => _diseaseSearchQuery;
  String? get diseaseDetectionFilter => _diseaseDetectionFilter;
  List<String> get diseaseSpeciesFilter => _diseaseSpeciesFilter;
  String? get diseaseSeverityFilter => _diseaseSeverityFilter;
  List<String> get diseaseCategoriesFilter => _diseaseCategoriesFilter;
  bool? get diseaseContagiousFilter => _diseaseContagiousFilter;
  String get diseaseSortBy => _diseaseSortBy;

  void saveDiseaseState({
    required int currentPage,
    required String searchQuery,
    required String? detectionFilter,
    required List<String> speciesFilter,
    required String? severityFilter,
    required List<String> categoriesFilter,
    required bool? contagiousFilter,
    required String sortBy,
  }) {
    _diseaseCurrentPage = currentPage;
    _diseaseSearchQuery = searchQuery;
    _diseaseDetectionFilter = detectionFilter;
    _diseaseSpeciesFilter = List.from(speciesFilter);
    _diseaseSeverityFilter = severityFilter;
    _diseaseCategoriesFilter = List.from(categoriesFilter);
    _diseaseContagiousFilter = contagiousFilter;
    _diseaseSortBy = sortBy;
    print('💾 Saved disease management state: page=$currentPage, detection="$detectionFilter", species=$speciesFilter, severity="$severityFilter", categories=$categoriesFilter, contagious=$contagiousFilter, sort="$sortBy", search="$searchQuery"');
  }

  /// Reset disease state to defaults
  void resetDiseaseState() {
    _diseaseCurrentPage = 1;
    _diseaseSearchQuery = '';
    _diseaseDetectionFilter = null;
    _diseaseSpeciesFilter = [];
    _diseaseSeverityFilter = null;
    _diseaseCategoriesFilter = [];
    _diseaseContagiousFilter = null;
    _diseaseSortBy = 'name_asc';
  }

  /// Reset all states
  void resetAllStates() {
    resetClinicState();
    resetUserState();
    resetAppointmentState();
    resetScheduleState();
    resetBreedState();
    resetDiseaseState();
    print('🧹 All screen states reset to defaults');
  }

  /// Clear all states on sign out (reset to initial defaults)
  void clearOnSignOut() {
    resetAllStates();
    print('🔒 Screen states cleared for sign out');
  }
}
