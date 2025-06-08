import 'package:flutter/material.dart';

class mypage extends StatelessWidget {
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
                  'mypage',
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
