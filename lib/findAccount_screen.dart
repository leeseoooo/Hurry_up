import 'package:flutter/material.dart';
import 'db_function.dart';

class FindAccount extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("계정 찾기"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: '이름'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: '이메일'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  String result = await DBService().findByEmail(
                    nameController.text,
                    emailController.text,
                  );
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: Text(result),
                    ),
                  );
                },
                child: Text("이메일로 찾기"),
              ),
              Divider(),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: '전화번호'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  String result = await DBService().findByPhone(
                    nameController.text,
                    phoneController.text,
                  );
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: Text(result),
                    ),
                  );
                },
                child: Text("전화번호로 찾기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
