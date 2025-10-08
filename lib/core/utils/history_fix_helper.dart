import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/data_cache.dart';

class HistoryFixHelper {
  static final DataCache _cache = DataCache();
  
  /// Clear all user-related cache and force fresh data fetch
  static Future<void> clearAllUserCache() async {
    print('🔄 Clearing all user cache...');
    
    // Clear authentication cache
    AuthGuard.clearUserCache();
    
    // Clear data cache
    _cache.clear();
    
    print('✅ All cache cleared');
  }
  
  /// Clear specific user's assessment cache
  static void clearUserAssessmentCache(String userId) {
    final cacheKey = 'user_assessments_$userId';
    _cache.invalidate(cacheKey);
    print('🔄 Cleared assessment cache for user: $userId');
  }
  
  /// Clear specific user's appointment cache
  static void clearUserAppointmentCache(String userId) {
    final cacheKey = 'user_appointments_$userId';
    _cache.invalidate(cacheKey);
    print('🔄 Cleared appointment cache for user: $userId');
  }
  
  /// Force refresh all user data
  static Future<void> forceRefreshUserData(String userId) async {
    print('🔄 Force refreshing all data for user: $userId');
    
    clearUserAssessmentCache(userId);
    clearUserAppointmentCache(userId);
    
    // Clear user profile cache
    final profileCacheKey = 'user_profile_$userId';
    _cache.invalidate(profileCacheKey);
    
    print('✅ All user data cache cleared for: $userId');
  }
}