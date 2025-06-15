import 'dart:async';
import 'package:flutter/material.dart';
import 'addSchedule.dart';
import 'db_function.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'timetable.dart';
import 'sharing.dart';

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
      loadSchedules().then((_) {
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

  Future<void> loadSchedules() async {
    setState(() => isLoading = true);
    schedules = await DBService().fetchTodaySchedules(user_id);
    setState(() => isLoading = false);
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
                sharing.shareAllSchedules(schedules);
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
                            sharing.shareSchedule(schedule);
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
                            await DBService().deleteSchedule(schedule.start_time, user_id);
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
                            final success = await DBService().deleteSchedule(schedule.start_time, user_id);
                            if (success) {
                              setState(() {
                                isLoading = true;
                              });
                              await loadSchedules();
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
            loadSchedules();
          });
        },
        child: const Icon(Icons.add),
      ),
    );

  }
}
