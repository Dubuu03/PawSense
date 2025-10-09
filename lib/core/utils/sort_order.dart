// core/utils/sort_order.dart
enum SortOrder {
  ascending('Date (Oldest First)', 'asc'),
  descending('Date (Newest First)', 'desc');

  const SortOrder(this.displayName, this.value);

  final String displayName;
  final String value;

  /// Convert from string to enum
  static SortOrder fromString(String value) {
    switch (value.toLowerCase()) {
      case 'asc':
        return SortOrder.ascending;
      case 'desc':
        return SortOrder.descending;
      default:
        return SortOrder.descending; // Default to newest first
    }
  }
}