abstract class ExpenseStore {
  Future<List<Map<String, dynamic>>> fetchAll();

  Future<Map<String, dynamic>> insert(Map<String, dynamic> payload);

  Future<List<Map<String, dynamic>>> update(
    String id,
    Map<String, dynamic> payload,
  );

  Future<List<Map<String, dynamic>>> delete(String id);
}
