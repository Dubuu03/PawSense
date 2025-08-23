# Vet Profile Services Architecture

This directory contains a refactored and modular approach to managing veterinarian profile data. The original `VetProfileService` has been broken down into smaller, focused services that can be easily combined and extended.

## Service Overview

### 1. **ProfileManagementService** 
- **File**: `profile_management_service.dart`
- **Purpose**: Main profile data aggregation and caching
- **Key Functions**:
  - `getVetProfile()` - Get complete vet profile with caching
  - `clearCache()` - Clear cached profile data
  - `getCacheInfo()` - Get cache debugging info

### 2. **ClinicService**
- **File**: `clinic_service.dart`
- **Purpose**: Basic clinic information management
- **Key Functions**:
  - `getClinicData()` - Get clinic by user ID
  - `updateClinicBasicInfo()` - Update clinic basic information
  - `getCurrentUserClinic()` - Get current user's clinic
  - `clinicExists()` - Check if clinic exists
  - `createClinic()` - Create new clinic

### 3. **ClinicDetailsService**
- **File**: `clinic_details_service.dart`
- **Purpose**: Extended clinic details and settings
- **Key Functions**:
  - `getClinicDetails()` - Get clinic details by ID
  - `createClinicDetailsDocument()` - Create clinic details document
  - `updateClinicDetails()` - Update clinic settings
  - `getCurrentUserClinicDetails()` - Get current user's clinic details
  - `clinicDetailsExists()` - Check if clinic details exist

### 4. **ClinicServicesManagementService**
- **File**: `clinic_services_management_service.dart`
- **Purpose**: Managing clinic services (CRUD operations)
- **Key Functions**:
  - `addService()` - Add new clinic service
  - `updateService()` - Update existing service
  - `deleteService()` - Delete service
  - `toggleServiceStatus()` - Toggle service active status
  - `getClinicServices()` - Get all services
  - `getServiceById()` - Get service by ID
  - `fixExistingServices()` - Fix services with missing fields

### 5. **SpecializationService**
- **File**: `specialization_service.dart`
- **Purpose**: Managing veterinarian specializations
- **Key Functions**:
  - `addSpecialization()` - Add new specialization
  - `deleteSpecialization()` - Remove specialization
  - `updateSpecialization()` - Update specialization details
  - `getSpecializations()` - Get all specializations
  - `hasSpecialization()` - Check if specialization exists
  - `getSpecializationsByLevel()` - Filter by expertise level
  - `getCertifiedSpecializations()` - Get only certified ones

### 6. **VetProfileLegacyService** (Compatibility Layer)
- **File**: `vet_profile_legacy_service.dart`
- **Purpose**: Backward compatibility with existing code
- **Key Functions**: Delegates all calls to appropriate specialized services

## Migration Guide

### For New Development
Use the specialized services directly based on your needs:

```dart
// For profile data
import 'package:pawsense/core/services/profile_management_service.dart';

// For clinic operations
import 'package:pawsense/core/services/clinic_service.dart';

// For specializations
import 'package:pawsense/core/services/specialization_service.dart';

// For services management
import 'package:pawsense/core/services/clinic_services_management_service.dart';
```

### For Existing Code
Use the legacy service for minimal changes:

```dart
// Replace this:
import 'package:pawsense/core/services/vet_profile_service.dart';

// With this:
import 'package:pawsense/core/services/vet_profile_legacy_service.dart';
```

## Benefits of This Architecture

1. **Separation of Concerns**: Each service has a single responsibility
2. **Better Testability**: Smaller, focused services are easier to test
3. **Code Reusability**: Services can be combined in different ways
4. **Maintainability**: Changes to one area don't affect others
5. **Scalability**: Easy to extend individual services
6. **Performance**: Can cache different data types independently

## Future Extensions

The modular architecture allows for easy addition of new services:

- **CertificationService** - Manage vet certifications
- **AppointmentService** - Manage clinic appointments  
- **ReviewService** - Manage clinic reviews
- **NotificationService** - Handle clinic notifications
- **AnalyticsService** - Track clinic performance metrics

## Best Practices

1. **Use appropriate service**: Don't import ProfileManagementService if you only need ClinicService
2. **Clear cache when needed**: Call `ProfileManagementService.clearCache()` after data changes
3. **Handle errors**: All services return error states - handle them appropriately
4. **Use dependency injection**: Consider using GetIt or similar for service management
5. **Add logging**: Enable debug logs for troubleshooting

## Dependencies Between Services

```
ProfileManagementService
├── ClinicService
├── ClinicDetailsService  
└── SpecializationService

ClinicDetailsService
└── ClinicService (for fallback data)

SpecializationService
└── ClinicDetailsService (for document creation)
```

## Cache Strategy

- **ProfileManagementService**: 5-minute cache for complete profile data
- **Individual Services**: No caching (always fresh data)
- **Cache Invalidation**: Manual via `clearCache()` or automatic on data changes
