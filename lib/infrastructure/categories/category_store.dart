/// Raw data access for the categories table.
///
/// Payloads use the database column names. Only data columns travel here;
/// validation, ordering, guards and error translation live in the
/// repository. Implementations throw the provider's exception unwrapped.
abstract class CategoryStore {
  /// All rows visible to the current session, ordered by name.
  Future<List<Map<String, dynamic>>> fetchAll();

  /// Owner lookup for guards: `{user_id}` when the row is visible,
  /// null when it does not exist or belongs to another user.
  Future<Map<String, dynamic>?> fetchOwner(String id);

  /// Inserts a row from a name-only payload, returning the created row.
  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload);

  /// Updates only the name, returning the updated rows (empty when the
  /// row is not visible to the current session).
  Future<List<Map<String, dynamic>>> updateName(String id, String name);

  /// Deletes the row (no-op when it is not visible to the session).
  Future<void> delete(String id);
}
