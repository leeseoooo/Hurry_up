import 'package:flutter/material.dart';

class schedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'schedule',
                  style: TextStyle(color: Colors.black, fontSize: 30),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
