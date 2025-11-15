import 'package:flutter/material.dart';
import 'package:rtsprep/icons/app_icons.dart';
import 'package:rtsprep/Service/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class account_screen extends StatefulWidget {
  final VoidCallback onLogout;
  const account_screen({
    super.key,
    required this.onLogout,
  });

  @override
  State<account_screen> createState() => _account_screenState();
}

class _account_screenState extends State<account_screen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1,
      ),
      child: SingleChildScrollView(
         child:  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(AppIcons.account_circle, size: 80, color: Colors.grey[600]),

          SizedBox(height: 20),
          Text(
            "Ваш аккаунт",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ВЫХОД',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      )) ,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Подтверждение выхода"),
          content: Text("Вы уверены, что хотите выйти из аккаунта?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Отмена"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final _authService = AuthService();
                _authService.signOut();
                widget.onLogout();

              },
              child: Text(
                "Выйти",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}