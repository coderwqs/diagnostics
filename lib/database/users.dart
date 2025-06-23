import 'package:diagnosis/utils/database.dart';
import 'package:diagnosis/model/user.dart';

class UserDatabase {
  final DatabaseUtils _dbUtils = DatabaseUtils();

  Future<void> addUser(User user) async {
    String sql =
        '''
      INSERT INTO users (id, name, email, password, createdAt)
      VALUES ('${user.id}', '${user.name}', '${user.email}', '${user.password}', ${user.createdAt})
    ''';
    await _dbUtils.insert(sql);
  }

  Future<List<User>> getAllUsers() async {
    String sql = 'SELECT * FROM users';
    final List<Map<String, dynamic>> maps = await _dbUtils.query(sql);
    return List.generate(maps.length, (i) {
      return User.fromJson(maps[i]);
    });
  }

  Future<void> updateUser(User user) async {
    String sql =
        '''
      UPDATE users 
      SET name = '${user.name}', email = '${user.email}', password = '${user.password}', createdAt = ${user.createdAt}
      WHERE id = '${user.id}'
    ''';
    await _dbUtils.update(sql);
  }

  Future<void> deleteUser(String id) async {
    String sql = 'DELETE FROM users WHERE id = "$id"';
    await _dbUtils.delete(sql);
  }
}
