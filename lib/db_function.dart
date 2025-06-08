import 'package:mysql_client/mysql_client.dart'; //for. SQL DB
import 'dart:async';

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