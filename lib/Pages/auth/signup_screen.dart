import 'package:flutter/material.dart';
import 'package:rtsprep/Service/auth_service.dart';

class signup_screen extends StatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback onSignUpSuccess;

  const signup_screen({
    super.key,
    required this.onToggle,
    required this.onSignUpSuccess,
  });

  @override
  State<signup_screen> createState() => _signup_screenState();
}

class _signup_screenState extends State<signup_screen> {
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

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }
    if (!validateEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите корректный email')),
      );
      return;
    } else if (!validatePassword(_passwordController.text)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Подтверждение почты'),
            content: Text(
                'Вам на почту пришло письмо. Перейдите по ссылке для подтверждения пароля'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: Text('ОК'),
              ),
            ],
          ),
        );
        widget.onToggle();
      }
    } catch (e) {
      String errorString = e.toString();
      if (errorString.contains('is invalid')) {
        print('Ошибка регистрации: Email address is invalid');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неверный адрес email')),
        );
      } else if (errorString.contains('User already registered')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Такой пользователь уже есть')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorString)),
        );
        print(errorString);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool validateEmail(String value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    return regex.hasMatch(value);
  }


  bool validatePassword(String value) {

    if(value.length < 8){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароль должен содержать минимум 8 симолов')),
      );
      return false;
    }
    else if(RegExp(r'^[a-z]+$').hasMatch(value)){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароль должен содержать цифры')),
      );
      return false;
    }
    else if(RegExp(r'^[0-9]+$').hasMatch(value)){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароль должен содержать буквы')),
      );
      return false;
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1,
      ),
      child: SingleChildScrollView( child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Text(
            "Регистрация",
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'Зарегистрироваться',
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
                'Уже есть аккаунт? ',
                style: TextStyle(fontSize: 16),
              ),
              GestureDetector(
                onTap: widget.onToggle,
                child: Text(
                  'Войти',
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
      ),) ,
    );
  }
}