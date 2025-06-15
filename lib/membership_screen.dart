//지도 화면
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'db_function.dart';

class join_membership extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: Center(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 40, color: Colors.black),
                    ]))),
        body: Center(child: join_membershipScreen()),
      ),
    );
  }
}

class join_membershipScreen extends StatelessWidget {
  final TextEditingController newidController = TextEditingController();
  final TextEditingController newpasswordController = TextEditingController();
  final TextEditingController newnameController = TextEditingController();
  final TextEditingController e_mailController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: Text(
                '회원가입',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                ),
              ),
            ),
            SizedBox(height: 10),
            inputField('ID (10자 이하로 입력하세요)', newidController, Icons.person),
            inputField('비밀번호 (20자 이하로 입력하세요)', newpasswordController, Icons.key),
            inputField('이름 (20자 이하로 입력하세요)', newnameController, Icons.person),
            inputField('이메일 (20자 이하로 입력하세요)', e_mailController, Icons.local_post_office),
            inputField('생년월일 (0000-00-00)', birthController, Icons.today),
            inputField('전화번호 (숫자만 입력)', phoneController, Icons.phone),
            SizedBox(height: 16),
            Container(
              width: 450,
              child: ElevatedButton(
                onPressed: () async {
                  if (newidController.text.isEmpty ||
                      newpasswordController.text.isEmpty ||
                      newnameController.text.isEmpty ||
                      e_mailController.text.isEmpty ||
                      birthController.text.isEmpty ||
                      phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('모든 항목을 입력해주세요.')),
                    );
                    return;
                  }
                  bool isDuplicate = await DBService().checkDuplicateID(newidController.text);
                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('이미 존재하는 ID입니다.')),
                    );
                    return;
                  }
                  bool success = await DBService().addPersonToDB(
                    newid: newidController.text,
                    newPassword: newpasswordController.text,
                    newname: newnameController.text,
                    newEmail: e_mailController.text,
                    birth: birthController.text,
                    phone: phoneController.text,
                  );

                  if (success) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => login()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('회원가입에 실패했습니다.')),
                    );
                  }
                },
                child: Text(
                  '작성 완료!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.lightBlueAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: 450,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            labelText: label,
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
