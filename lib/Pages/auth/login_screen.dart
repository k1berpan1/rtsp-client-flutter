import 'package:flutter/material.dart';
import 'package:rtsprep/Service/auth_service.dart';

class login_screen extends StatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback onLoginSuccess;

  const login_screen({
    super.key,
    required this.onToggle,
    required this.onLoginSuccess,
  });

  @override
  State<login_screen> createState() => _login_screenState();
}

class _login_screenState extends State<login_screen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вход успешен!')),
        );
        widget.onLoginSuccess();
      }
    }
    catch (e) {
      String errorString = e.toString();
      if (errorString.contains('Email not confirmed')) {
        print('Ошибка входа: Email not confirmed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Подтвердите email')),
        );
      }
      else if (errorString.contains('Invalid login credentials')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неверный email или пароль')),
        );
      }
      else{
        print('Не обработанная ошибка: $errorString' );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' ${e.toString()}')),
        );
      }

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void password_recovery(){
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите email')),
      );
      return;
    }


  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1,
      ),
      child:  SingleChildScrollView(child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Text(
            "Вход",
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.08,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),

          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.025),

          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Пароль',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
          ),


          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'Войти',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Нет аккаунта? ',
                style: TextStyle(fontSize: 16),
              ),
              GestureDetector(
                onTap: widget.onToggle,
                child: Text(
                  'Регистрация',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),),
    );
  }
}