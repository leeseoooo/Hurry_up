import 'package:mysql_client/mysql_client.dart'; //for. SQL DB
import 'dart:async';
import 'login_screen.dart';

Future<MySQLConnection> connect_db() async {
  // MySQL 접속 설정
  final conn = await MySQLConnection.createConnection(
    host: '10.0.2.2',
    port: 3306,
    userName: 'root',
    password: '0000',
    databaseName: 'hurry_up', // optional
  );

  await conn.connect();
  print("DB Connected");
  return conn;
}

Future<void> disconnect_db(MySQLConnection conn) async {
  await conn.close();
  print ('DB Disconnected');
}

Future<bool> deleteScheduleFromDB(String startTime) async {
  final conn = await connect_db();
  try {
    var result = await conn.execute(
      "DELETE FROM timetable WHERE ID = :id AND start_time = :start_time",
      {
        'id': user_id,
        'start_time': startTime,
      },
    );

    // 결과에서 삭제된 행 수 확인
    if (result.affectedRows != null) {
      return result.affectedRows.toInt() > 0;
    } else {
      print("⚠️ 삭제 결과에서 affectedRows를 찾을 수 없습니다. 삭제 성공 여부를 판단할 수 없음.");
      return false;
    }
  } catch (e) {
    print("삭제 중 오류 발생: $e");
    return false;
  } finally {
    await disconnect_db(conn);
  }
}
