import 'package:flutter_test/flutter_test.dart';
import 'package:pawsense/core/models/user/pet_model.dart';

void main() {
  group('Pet Model Dynamic Age Tests', () {
    test('Pet age should increase over time', () {
      // Create a pet that was created 2 months ago with initial age of 6 months
      final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
      
      final pet = Pet(
        userId: 'test-user',
        petName: 'Buddy',
        petType: 'Dog',
        initialAge: 6, // 6 months old when created
        weight: 5.0,
        breed: 'Golden Retriever',
        createdAt: twoMonthsAgo,
        updatedAt: twoMonthsAgo,
      );

      // The pet should now be approximately 8 months old (6 initial + 2 months passed)
      expect(pet.age, greaterThanOrEqualTo(7)); // At least 7 months (accounting for some variance)
      expect(pet.age, lessThanOrEqualTo(9)); // At most 9 months (accounting for some variance)
      
      print('Pet initial age: ${pet.initialAge} months');
      print('Pet current age: ${pet.age} months');
      print('Pet age string: ${pet.ageString}');
    });

    test('Pet age string formatting should work correctly', () {
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      
      final pet = Pet(
        userId: 'test-user',
        petName: 'Max',
        petType: 'Cat',
        initialAge: 12, // 1 year old when created
        weight: 3.0,
        breed: 'Persian',
        createdAt: oneYearAgo,
        updatedAt: oneYearAgo,
      );

      // Should be approximately 2 years old now
      expect(pet.ageString, contains('year'));
      print('Pet age string after 1 year: ${pet.ageString}');
    });

    test('Newly created pet should have initial age', () {
      final now = DateTime.now();
      
      final pet = Pet(
        userId: 'test-user',
        petName: 'Luna',
        petType: 'Dog',
        initialAge: 3,
        weight: 2.0,
        breed: 'Chihuahua',
        createdAt: now,
        updatedAt: now,
      );

      // Should have the same age as initial age since it was just created
      expect(pet.age, equals(3));
      expect(pet.ageString, equals('3 months'));
    });
  });
}