import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'mypage_screen.dart';
import 'schedule_screen.dart';

class MyApp extends StatefulWidget {

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 1;

  List<Widget> _widgetOptions = <Widget>[
    schedule(),
    home(),
    MyPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
            title: Center(
              child:
              Text('Hurry Up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,),
              ),
            )
        ),
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          //fixed, shifting
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Schedule',
                backgroundColor: Color(0xFF6DA168)),
            BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
                backgroundColor: Color(0xB15FBFFF)),
            BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Mypage',
                backgroundColor: Color(0xFFBFA2DB))
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.yellowAccent,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
