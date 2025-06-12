import 'package:flutter/material.dart';
import 'db_function.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final data = await DBService().fetchUserInfo(user_id);

    if (data.isNotEmpty) {
      idController.text = data['id']!;
      passwordController.text = data['password']!;
      nameController.text = data['name']!;
      emailController.text = data['email']!;

      final birth = data['birth']!;
      try {
        DateTime birthDate = DateTime.parse(birth);
        birthController.text = DateFormat('yyyy-MM-dd').format(birthDate);
      } catch (e) {
        birthController.text = birth;
      }

      phoneController.text = data['phone']!;
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateUserInfo() async {
    await DBService().updateUserInfo(
      id: idController.text,
      password: passwordController.text,
      name: nameController.text,
      email: emailController.text,
      birth: birthController.text,
      phone: phoneController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('정보가 수정되었습니다')),
    );
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => login()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('마이페이지'),
          actions: [
            ElevatedButton(
              onPressed: logout,
              child: Text('로그아웃'),
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              buildField('ID', idController, readOnly: true),
              buildField('Password', passwordController),
              buildField('Name', nameController),
              buildField('Email', emailController),
              buildField('Birth', birthController),
              buildField('Phone', phoneController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateUserInfo,
                child: Text('수정 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}