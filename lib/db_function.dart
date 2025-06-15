import 'package:mysql_client/mysql_client.dart';
import 'login_screen.dart';
import 'timetable.dart';

class DBService {
  Future<MySQLConnection> connect_db() async {
    final conn = await MySQLConnection.createConnection(
      host: '10.0.2.2',
      port: 3306,
      userName: 'root',
      password: '0000',
      databaseName: 'hurry_up',
    );

    await conn.connect();
    print("DB Connected");
    return conn;
  }

  Future<void> disconnect_db(MySQLConnection conn) async {
    await conn.close();
    print('DB Disconnected');
  }

  Future<bool> addScheduleToDB({
    required String name,
    required String start,
    required String finish,
    required String place,
    required double lat,
    required double lng,
    required bool switchValue,
  }) async {
    final conn = await connect_db();
    try {
      var result = await conn.execute(
        "INSERT INTO timetable (name, start_time, finish_time, place, ID, lat, lng, switch_value) "
            "VALUES (:new_name, :new_start, :new_finish, :new_place, :id, :new_lat, :new_lng, :val_switch)",
        {
          "new_name": name,
          "new_start": start,
          "new_finish": finish,
          "new_place": place,
          "id": user_id,
          "new_lat": lat,
          "new_lng": lng,
          "val_switch": switchValue,
        },
      );
      return result != null;
    } catch (e) {
      print("DB 삽입 오류: $e");
      return false;
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<String> findByEmail(String name, String email) async {
    final conn = await connect_db();
    try {
      var result = await conn.execute(
        "SELECT ID, password FROM member WHERE name = :name AND email = :email",
        {"name": name, "email": email},
      );
      if (result.rows.isNotEmpty) {
        String id = result.rows.first.colAt(0) ?? '';
        String pw = result.rows.first.colAt(1) ?? '';
        return 'ID: $id\n비밀번호: $pw';
      } else {
        return '일치하는 계정을 찾을 수 없습니다.';
      }
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<String> findByPhone(String name, String phone) async {
    final conn = await connect_db();
    try {
      var result = await conn.execute(
        "SELECT ID, password FROM member WHERE name = :name AND phone = :phone",
        {"name": name, "phone": phone},
      );
      if (result.rows.isNotEmpty) {
        String id = result.rows.first.colAt(0) ?? '';
        String pw = result.rows.first.colAt(1) ?? '';
        return 'ID: $id\n비밀번호: $pw';
      } else {
        return '일치하는 계정을 찾을 수 없습니다.';
      }
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<bool> checkPassword(String ID, String Password) async {
    bool checklogin = false;
    final conn = await connect_db();
    try {
      var result = await conn.execute('SELECT * FROM hurry_up.member');
      for (final row in result.rows) {
        String id = row.colAt(0) ?? 'noID';
        String password = row.colAt(1) ?? 'noPassword';
        if (id == ID && password == Password) {
          checklogin = true;
          user_id = id;
          break;
        }
      }
    } catch (e) {
      print("로그인 중 오류 발생: $e");
    } finally {
      await disconnect_db(conn);
    }
    return checklogin;
  }

  Future<bool> addPersonToDB({
    required String newid,
    required String newPassword,
    required String newname,
    required String newEmail,
    required String birth,
    required String phone,
  }) async {
    final conn = await connect_db();
    try {
      var result = await conn.execute(
        "INSERT INTO member (ID, password, name, email, birth, phone) "
            "VALUES (:new_id, :newPassword, :new_name, :new_email, :birth, :phone)",
        {
          "new_id": newid,
          "newPassword": newPassword,
          "new_name": newname,
          "new_email": newEmail,
          "birth": birth,
          "phone": phone,
        },
      );
      return result != null;
    } catch (e) {
      print("회원가입 중 오류 발생: $e");
      return false;
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<Map<String, String>> fetchUserInfo(String userId) async {
    final conn = await connect_db();
    try {
      var result = await conn.execute(
        'SELECT ID, password, name, email, birth, phone FROM hurry_up.member WHERE ID = :uid',
        {'uid': userId},
      );

      if (result.rows.isNotEmpty) {
        final row = result.rows.first;
        return {
          'id': row.colAt(0) ?? '',
          'password': row.colAt(1) ?? '',
          'name': row.colAt(2) ?? '',
          'email': row.colAt(3) ?? '',
          'birth': row.colAt(4) ?? '',
          'phone': row.colAt(5) ?? '',
        };
      } else {
        return {};
      }
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<void> updateUserInfo({
    required String id,
    required String password,
    required String name,
    required String email,
    required String birth,
    required String phone,
  }) async {
    final conn = await connect_db();
    try {
      await conn.execute(
        'UPDATE hurry_up.member SET password = :pwd, name = :name, email = :email, birth = :birth, phone = :phone WHERE ID = :uid',
        {
          'pwd': password,
          'name': name,
          'email': email,
          'birth': birth,
          'phone': phone,
          'uid': id,
        },
      );
    } catch (e) {
      print("사용자 정보 업데이트 실패: $e");
      throw Exception("데이터베이스 저장 중 오류가 발생했습니다.");
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<List<Timetable>> fetchTodaySchedules(String userId) async {
    final conn = await connect_db();
    final List<Timetable> todaySchedules = [];

    try {
      final result = await conn.execute(
        'SELECT name, start_time, finish_time, place, ID, lat, lng, switch_value '
            'FROM hurry_up.timetable WHERE ID = :uid',
        {'uid': userId},
      );

      DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
      DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      for (final row in result.rows) {
        String name = row.colAt(0) ?? 'noName';
        String start_time = row.colAt(1) ?? 'Unknown';
        String finish_time = row.colAt(2) ?? 'Unknown';
        String place = row.colAt(3) ?? 'noPlace';
        String ID = row.colAt(4) ?? 'noID';
        double lat = double.tryParse(row.colAt(5)?.toString() ?? '') ?? 0.0;
        double lng = double.tryParse(row.colAt(6)?.toString() ?? '') ?? 0.0;
        bool switch_value = (row.colAt(7)?.toString() == '1');

        try {
          DateTime startTime = DateTime.parse(start_time);
          DateTime finishTime = DateTime.parse(finish_time);

          if (finishTime.isAfter(todayStart) && startTime.isBefore(todayEnd)) {
            todaySchedules.add(Timetable(name, start_time, finish_time, place, ID, lat, lng, switch_value));
          }
        } catch (_) {}
      }
    } finally {
      await disconnect_db(conn);
    }

    return todaySchedules;
  }

  Future<bool> deleteSchedule(String startTime, String userId) async {
    final conn = await connect_db();
    try {
      final result = await conn.execute(
        "DELETE FROM timetable WHERE ID = :id AND start_time = :start_time",
        {
          'id': userId,
          'start_time': startTime,
        },
      );
      return result.affectedRows != null && result.affectedRows.toInt() > 0;
    } finally {
      await disconnect_db(conn);
    }
  }

  Future<bool> checkDuplicateID(String newid) async {
    final conn = await connect_db();
    try {
      final result = await conn.execute(
        'SELECT COUNT(*) FROM member WHERE ID = :id',
        {'id': newid},
      );

      if (result.rows.isNotEmpty) {
        int count = int.tryParse(result.rows.first.colAt(0) ?? '0') ?? 0;
        return count > 0;
      } else {
        return false;
      }
    } catch (e) {
      print("ID 중복 확인 오류: $e");
      return true;
    } finally {
      await disconnect_db(conn);
    }
  }

}


