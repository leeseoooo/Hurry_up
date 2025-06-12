import 'dart:async';
import 'package:flutter/material.dart';
import 'addSchedule.dart';
import 'db_function.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

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
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    initNotifications();

    requestNotificationPermission().then((_) {
      dbConnector().then((_) {
        startScheduleCheckTimer();
      });
    });
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'schedule_channel_id',
      'Schedule Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // notification ID
      title,
      body,
      notificationDetails,
    );
  }

  void startScheduleCheckTimer() {
    Timer.periodic(Duration(minutes: 10), (timer) {
      for (var schedule in schedules) {
        checkScheduleAndNotify(schedule);
      }
    });
  }

  Future<void> checkScheduleAndNotify(Timetable schedule) async {
    try {
      if (!schedule.switch_value) return;

      Position current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        schedule.lat,
        schedule.lng,
      );

      int walkMinutes = (distance / 1.33 / 60).round();
      DateTime startTime = DateTime.parse(schedule.start_time);
      int minutesUntilStart = startTime.difference(DateTime.now()).inMinutes;

      int bufferMinutes = 5; // 도착 전 여유

      if (minutesUntilStart <= 60 && (walkMinutes + bufferMinutes) >= minutesUntilStart) {
        await sendNotification(
          "${schedule.name}",
          "예상 도보 시간: ${walkMinutes}분\n남은 시간: ${minutesUntilStart}분\n장소: ${schedule.place}",
        );
      }
    } catch (e) {
      print("거리 계산 실패: $e");
    }
  }

  void initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> dbConnector() async {
    print("Connecting to mysql server...");
    schedules.clear();
    final conn = await connect_db();
    var result = await conn.execute('SELECT name, start_time, finish_time, place, ID, lat, lng, switch_value '
        'FROM hurry_up.timetable WHERE ID = :uid', {'uid': user_id.toString()},
    );

    for (final row in result.rows) {
      String name = row.colAt(0) ?? 'noName';
      String start_time = row.colAt(1) ?? 'Unknown';
      String finish_time = row.colAt(2) ?? 'Unknown';
      String place = row.colAt(3) ?? 'noPlace';
      String ID = row.colAt(4) ?? 'noID';
      double lat = double.tryParse(row.colAt(5)?.toString() ?? '') ?? 0.0;
      double lng = double.tryParse(row.colAt(6)?.toString() ?? '') ?? 0.0;
      bool switch_value = (row.colAt(7)?.toString() == '1');

      DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
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

  }

  Future<void> shareScheduleKakao(Timetable schedule) async {
    try {
      String formattedStart = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(schedule.start_time));
      String formattedFinish = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(schedule.finish_time));

      final template = FeedTemplate(
        content: Content(
          title: '${schedule.name}',
          description: '$formattedStart ~ $formattedFinish\n장소: ${schedule.place}',
          imageUrl: Uri.parse('https://via.placeholder.com/300x200.png?text=Schedule'),
          link: Link(
            webUrl: Uri.parse('https://developers.kakao.com'),
            mobileWebUrl: Uri.parse('https://developers.kakao.com'),
          ),
        ),
      );

      final isAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (isAvailable) {
        await ShareClient.instance.shareDefault(template: template);
      } else {
        final uri = await WebSharerClient.instance.makeDefaultUrl(template: template);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("카카오 공유 오류: $e");
    }
  }

  Future<void> shareAllSchedulesKakao(List<Timetable> allSchedules) async {
    try {
      if (allSchedules.isEmpty) return;

      String combinedText = allSchedules.map((schedule) {
        String formattedStart = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(schedule.start_time));
        String formattedFinish = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(schedule.finish_time));
        return "- ${schedule.name}\n  ${formattedStart} ~ ${formattedFinish}\n  장소: ${schedule.place}";
      }).join("\n\n");

      final template = FeedTemplate(
        content: Content(
          title: "오늘의 전체 일정",
          description: combinedText,
          imageUrl: Uri.parse('https://via.placeholder.com/300x200.png?text=Schedules'),
          link: Link(
            webUrl: Uri.parse('https://developers.kakao.com'),
            mobileWebUrl: Uri.parse('https://developers.kakao.com'),
          ),
        ),
      );

      final isAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (isAvailable) {
        await ShareClient.instance.shareDefault(template: template);
      } else {
        final uri = await WebSharerClient.instance.makeDefaultUrl(template: template);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("전체 일정 카카오 공유 오류: $e");
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
                shareAllSchedulesKakao(schedules);
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            shareScheduleKakao(schedule);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: Size(60, 24),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            textStyle: TextStyle(fontSize: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text("공유"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await deleteScheduleFromDB(schedule.start_time);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => (set_schedule())), // 이동할 화면 위젯
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[100],
                            foregroundColor: Colors.black,
                            minimumSize: Size(60, 24),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            textStyle: TextStyle(fontSize: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text("수정"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await deleteScheduleFromDB(schedule.start_time);
                            if (success) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => set_schedule()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('삭제에 실패했습니다.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.black,
                            minimumSize: Size(60, 24),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            textStyle: TextStyle(fontSize: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text("삭제"),
                        ),

                      ],
                    )

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
