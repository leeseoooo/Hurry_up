import 'package:flutter/material.dart';
import 'addSchedule.dart';
import 'db_function.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'package:geolocator/geolocator.dart';

class Timetable {
  String name;
  String start_time;
  String finish_time;
  String place;
  String ID;
  double lat;
  double lng;
  bool switch_value;
  Timetable(this.name, this.start_time, this.finish_time, this.place, this.ID,this.lat, this.lng, this.switch_value);
}

class schedule extends StatefulWidget {
  @override
  _ScheduleState createState() => _ScheduleState();
}

List<Timetable> schedules = [];
class _ScheduleState extends State<schedule> {
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    dbConnector();
  }

  Future<void> dbConnector() async {
    print("Connecting to mysql server...");
    schedules.clear();
    final conn = await connect_db();
    var result = await conn.execute('SELECT name, start_time, finish_time, place, lat, lng, switch_value '
        'FROM hurry_up.timetable WHERE ID = :uid', {'uid': user_id.toString()},
    );

    for (final row in result.rows) {
      String name = row.colAt(0) ?? 'noName';
      String start_time = row.colAt(1) ?? 'Unknown';
      String finish_time = row.colAt(2) ?? 'Unknown';
      String place = row.colAt(3) ?? 'noPlace';
      String ID = row.colAt(4) ?? 'noID';
      double lat = double.tryParse(row.colAt(4)?.toString() ?? '') ?? 0.0;
      double lng = double.tryParse(row.colAt(5)?.toString() ?? '') ?? 0.0;
      bool switch_value = (row.colAt(6)?.toString() == '1');
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      try {
        DateTime startTime = DateTime.parse(start_time);
        DateTime finishTime = DateTime.parse(finish_time);

        // 오늘 날짜 범위 안에 일정이 걸쳐 있을 때만 추가
        if (finishTime.isAfter(todayStart) && startTime.isBefore(todayEnd)) {
          schedules.add(Timetable(name, start_time, finish_time, place, ID, lat, lng, switch_value));
        }
      } catch (e) {
        print('날짜 파싱 오류: $e');
      }
    }

    await disconnect_db(conn);
    setState(() {
      isLoading = false;
    });

    Future<void> checkScheduleAndNotify(Timetable schedule) async {
      try {
        Position current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        double distance = Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          schedule.lat,
          schedule.lng,
        );

        int walkMinutes = (distance / 1.33 / 60).round(); // 평균 1.33m/s
        DateTime startTime = DateTime.parse(schedule.start_time);
        int minutesUntilStart = startTime.difference(DateTime.now()).inMinutes;

        if (minutesUntilStart <= 60 && walkMinutes > minutesUntilStart) {
          print('출발');
        }
      } catch (e) {
        print("거리 계산 실패: $e");
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF6DA168),
        centerTitle: true,
        title: Text("Today's Schedule"),
      ),
      body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's schedule",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => set_schedule()),
                );
              },
              child: Text(
                '전체공유',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: schedules.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white),
            itemBuilder: (context, index) {
              final schedule = schedules[index];

              String formattedStart = '시작 시간 오류';
              String formattedFinish = '종료 시간 오류';

              try {
                DateTime startTime = DateTime.parse(schedule.start_time);
                DateTime finishTime = DateTime.parse(schedule.finish_time);
                formattedStart = DateFormat('yyyy.MM.dd HH:mm').format(startTime);
                formattedFinish = DateFormat('yyyy.MM.dd HH:mm').format(finishTime);
              } catch (e) {
                print('날짜 형식 오류: $e');
              }
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.event_note, size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "$formattedStart ~ $formattedFinish\n장소 : ${schedule.place}",
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {

                      },
                      child: Text("공유"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );

            },
          ),
        ),
      ],
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => set_schedule()),
          ).then((_) {
            setState(() {
              isLoading = true;
            });
            dbConnector();
          });
        },
        child: const Icon(Icons.add),
      ),
    );

  }
}
