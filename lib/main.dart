import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'package:rtsprep/Pages/account_screen.dart';
import 'package:rtsprep/Pages/auth/signup_screen.dart';
import 'package:rtsprep/Pages/auth/login_screen.dart';

import 'package:rtsprep/Pages/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
      url: "",
      anonKey: ""
  );
  MediaKit.ensureInitialized();
  runApp(const MaterialApp(home: MyScreen()));
}
class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  @override
  State<MyScreen> createState() => MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  int myIndex = 0;
  bool showLogin = true;
  bool isLoggedIn = false;

  void toggleAuthScreen() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  void onAuthSuccess() {
    setState(() {
      isLoggedIn = true;
    });
  }

  List<Widget> get widgetList => [
    home_screen(),
    isLoggedIn
        ? account_screen(onLogout: () => setState(() => isLoggedIn = false))
        : (showLogin
        ? login_screen(
      onToggle: toggleAuthScreen,
      onLoginSuccess: onAuthSuccess,
    )
        : signup_screen(
      onToggle: toggleAuthScreen,
      onSignUpSuccess: onAuthSuccess,
    ))
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camview'),
        backgroundColor: Colors.blue,
      ),
      body:  Center(
        child: widgetList[myIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        currentIndex: myIndex,
        items: const[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Аккаунт')
        ],
      ),
    );
  }
}