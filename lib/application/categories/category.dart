/// Expense category as seen by the application.
///
/// [userId] is null for system categories and holds the owner's id for
/// private ones. It is read-only metadata: the UI must never edit it and
/// ownership is always derived from the authenticated session server-side.
class Category {
  const Category({required this.id, required this.name, required this.userId});

  final String id;
  final String name;
  final String? userId;

  /// System categories are read-only; private ones belong to the user.
  bool get isSystem => userId == null;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
    );
  }
}
