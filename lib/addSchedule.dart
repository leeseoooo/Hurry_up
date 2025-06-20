//스케줄 추가
import 'package:flutter/material.dart';
import 'db_function.dart';
import 'schedule_screen.dart';
import 'map_screen.dart';

class set_schedule extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 40, color: Colors.black),
              ],
            ),
          ),
        ),
        body: Center(child: addPersonScreen()),
      ),
    );
  }
}

class addPersonScreen extends StatefulWidget {
  @override
  _addPersonScreenState createState() => _addPersonScreenState();
}

class _addPersonScreenState extends State<addPersonScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController startDateTimeController = TextEditingController();
  final TextEditingController finishDateTimeController = TextEditingController();
  double? selectedLat;
  double? selectedLng;
  bool switchValue = false;

  Future<void> pickStartDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2016),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    DateTime combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      startDateTimeController.text = combined.toString();
    });
  }

  Future<void> pickFinishDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2016),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    DateTime combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      finishDateTimeController.text = combined.toString();
    });
  }

  void showMessage(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text('확인'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    placeController.text = '';
    selectedLat = null;
    selectedLng = null;
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text('일정 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 10),
            buildInputField(nameController, '일정 이름', Icons.schedule),
            SizedBox(height: 16),
            buildInputField(startDateTimeController, '일정 시작', Icons.timelapse, onTap: pickStartDateTime),
            SizedBox(height: 16),
            buildInputField(finishDateTimeController, '일정 끝', Icons.timelapse, onTap: pickFinishDateTime),
            SizedBox(height: 16),
            buildInputField(
              placeController,
              '장소',
              Icons.place_outlined,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );

                if (result != null) {
                  setState(() {
                    selectedLat = result['lat'];
                    selectedLng = result['lng'];
                    placeController.text = result['placeName'];
                  });
                }
              },
            ),
            SizedBox(height: 16),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(' '),
                  Icon(Icons.alarm),
                  Text('  알림 설정                                     ', style: TextStyle(fontSize: 20)),
                  Switch(
                    value: switchValue,
                    onChanged: (bool value) {
                      setState(() {
                        switchValue = value;
                      });
                    },
                  ),
                ]
            ),
            SizedBox(height: 16),
            ElevatedButton(
                onPressed: () async {
                  String name = nameController.text;
                  String start = startDateTimeController.text;
                  String finish = finishDateTimeController.text;
                  String place = placeController.text;

                  if (name.isEmpty || start.isEmpty || finish.isEmpty || place.isEmpty || selectedLat == null || selectedLng == null) {
                    showMessage('모든 항목을 입력해주세요.');
                    return;
                  }

                  DateTime startDT = DateTime.parse(start);
                  DateTime finishDT = DateTime.parse(finish);
                  if (startDT.isAfter(finishDT)) {
                    showMessage('시작 시간은 종료 시간보다 빨라야 합니다.');
                    return;
                  }

                  if (selectedLat == null || selectedLng == null) {
                    showMessage('장소를 지도에서 선택해주세요.');
                    return;
                  }

                  bool success = await DBService().addScheduleToDB(
                    name: nameController.text,
                    start: start,
                    finish: finish,
                    place: placeController.text,
                    lat: selectedLat!,
                    lng: selectedLng!,
                    switchValue: switchValue,
                  );

                  if (!mounted) return;
                  if (success) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => schedule()),
                    );
                  } else {
                    showMessage('일정 추가에 실패했습니다.');
                  }
                },
                child: Text('작성 완료!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent),
            ),
          ],
        ),
      ),
    );

  }

  Widget buildInputField(TextEditingController controller, String label, IconData icon, {VoidCallback? onTap}) {
    return Container(
      width: 450,
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
