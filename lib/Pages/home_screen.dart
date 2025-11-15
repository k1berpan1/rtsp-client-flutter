import 'package:flutter/material.dart';
import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart' as ffmpeg_session;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rtsprep/Service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

class home_screen extends StatefulWidget {
  const home_screen({Key? key}) : super(key: key);

  @override
  State<home_screen> createState() => _home_screenState();
}

class _home_screenState extends State<home_screen> {
  late TextEditingController controllerforfield;
  late final Player player;
  late final VideoController controller;
  String rtsplink = '';
  bool isRecording = false;
  FFmpegSession? _recordingSession;
  final SupabaseClient _client = Supabase.instance.client;
  bool isConnected = false;
  StreamSubscription? _internetConnectionSteramSubscription;
  final AuthService _authService = AuthService();
  String? _userId;
  bool _isPlayerInitialized = false;
  bool isFirst = true;
  String full_path ='';
  bool perm = false;

  @override
  void initState() {
    super.initState();
    controllerforfield = TextEditingController();
    player = Player();
    controller = VideoController(player);
    _restorePermissionStatus();
    _authService.authStateChanges.listen((AuthState state)  {
      setState(() {
        _userId = _authService.currentUser?.id;
      });
      _getData().then((_) {
        playerState();
      });
    });

    _initApp();
  }

  Future<void> _initApp() async {
    _getCurrentUserId();
    checkConnection();
    print('_initApp');
  }

  Future<void> _restorePermissionStatus() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      perm = _prefs.getBool('storage_permission') ?? false;
    });
    print('Restored permission status: $perm');
  }

  Future<void> _saveData(int oper) async {
    if(oper == 1){
      if(_userId == null){
        try {
          SharedPreferences _prefs = await SharedPreferences.getInstance();
          await _prefs.setString('link', rtsplink);
          print('link saved in device: $rtsplink');
        }
        catch (e) {
          print('Error saving data: $e');
        }
      }
      return;
    }
    else if (oper == 2){
      try {
        SharedPreferences _prefs = await SharedPreferences.getInstance();
        await _prefs.setString('full_path', full_path);
        print('full_path saved in device:: $full_path');
      }
      catch (e) {
        print('Error saving data: $e');
      }
    }
    else{
      SharedPreferences _prefs = await SharedPreferences.getInstance();
      await _prefs.setBool('storage_permission', perm);
    }
  }

  Future<void> _getData() async {
    if (_userId != null) {
      final response = await _client
          .from('user_link')
          .select('link')
          .eq('user_id', _userId!);

      if (response.isNotEmpty) {
        final linkFromDb = response[0]['link'] as String;
        print(' ссылка: $linkFromDb');
        setState(() {
          rtsplink = linkFromDb;
        });
        print(' ссылка с user: $linkFromDb');
      }
      else {
        print('Ссылка не найдена для пользователя: $_userId');
      }
    }
    else {
      SharedPreferences _prefs = await SharedPreferences.getInstance();
      String? savedLink = _prefs.getString('link') ?? 'rtsp://rtspstream:z7zG6v7OVYaLYA8lCX3-f@zephyr.rtsp.stream/movie';
      print(' ссылка сохраненная: $savedLink');

      setState(() {
        rtsplink = savedLink!;
      });
    }
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      full_path = _prefs.getString('full_path') ?? '';
    });
    print('_getData called');
  }

  Future<void> showealert(String textfortitle, String textforcontent) async => await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
          title: Text(textfortitle),
          content: Text(textforcontent),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: Text('Закрыть')
            ),
          ]
      )
  );

  Future<String?> inputrtsp() async {
    final currentOrientation = MediaQuery.of(context).orientation;
    final isLandscape = currentOrientation == Orientation.landscape;

    if (isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    String? result;

    try {
      result = await showDialog<String>(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Добавить ссылку',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ссылка',
                    border: OutlineInputBorder(),
                  ),
                  controller: controllerforfield,
                  onSubmitted: (_) => submit(),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, ''),
                        child: Text('Отмена')
                    ),
                    SizedBox(width: 8),
                    TextButton(
                        onPressed: submit,
                        child: Text(
                          'Добавить',
                          style: TextStyle(color: Colors.blue),
                        )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    return result;
  }

  void checkConnection() {
    _internetConnectionSteramSubscription = InternetConnection().onStatusChange.listen((event) {
      print(event);
      event == InternetStatus.connected;
      switch(event) {
        case InternetStatus.connected:
          setState(() {
            isConnected = true;
          });
          if(isFirst && isConnected){
            setState(() {
              isConnected = false;
            });
            break;
          }
          showealert('Интернет подключение', 'Есть Интернет подключение');
          break;
        case InternetStatus.disconnected:
          setState(() {
            isConnected = false;
          });
          showealert('Интернет подключение', 'Нет Интернет подключения');
          break;
        default:
          setState(() {
            isConnected = false;
          });
          showealert('Интернет подключение', 'Нет Интернет подключения');
          break;
      }
    });
  }

  void _getCurrentUserId() {
    final user = _authService.currentUser;
    setState(() {
      _userId = user?.id;
    });

    if (_userId != null) {
      print('Текущий пользователь ID: $_userId');
    } else {
      print('Пользователь не авторизован');
    }
  }

  Future<void> playerState() async {
    try {
      if (_isPlayerInitialized) {
        await player.stop();
      }

      print('Opening media: $rtsplink');
      await player.open(Media(rtsplink));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Медиа успешно открыто')),
      );
      print('Медиа успешно открыто: $rtsplink');

      setState(() {
        _isPlayerInitialized = true;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка открытия медиа')),
      );
      print('Ошибка открытия медиа: $error');
    }
  }

  Future<void> insertIntoBD() async {
    if (_userId == null) {
      print('User not authenticated, skipping database insert');
      return;
    }
    try {
      await _client.from('user_link').insert({
        'user_id': _userId,
        'link': rtsplink,
      });
      print('inserted into database');
    }
    catch (e) {
      print('Unexpected error: $e');
    }
  }

  void submit() {
    Navigator.of(context).pop(controllerforfield.text);
    controllerforfield.clear();
  }

  Future<bool> _requestStoragePermission() async {
    var permissionGranted = await Permission.manageExternalStorage.request();
    setState(() {
      perm = permissionGranted.isGranted;
    });
    _saveData(3);
    print('permision is ${perm}');
    return perm;
  }

  Future<bool> getSaveFilePath() async {
    if(!perm){
      bool permissionResult = await _requestStoragePermission();
      if (!permissionResult) {
        showealert('Ошибка выдачи разрешения','Вы не выдали разрешение. Оно нужно для сохранения видео.');
        return false;
      }
    }

    try {
      String? selectedPath = await FilePicker.platform.getDirectoryPath();
      if (selectedPath != null) {
        setState(() {
          full_path = selectedPath;
        });
        _saveData(2);
        showealert('Путь сохранен','Файлы будут сохраняться в $full_path');
        return true;
      }
      else {
        return false;
      }
    }
    catch (e) {
      print('Error getting save path: $e');
      return false;
    }
  }

  void _toggleRecording() async {
    if (!isRecording) {
      if (!perm) {
        bool permissionResult = await _requestStoragePermission();
        if (!permissionResult) {
          showealert('Ошибка выдачи разрешения','Вы не выдали разрешение. Оно нужно для сохранения видео.');
          return;
        }
      }

      if (full_path.isEmpty) {
        bool pathSelected = await getSaveFilePath();
        if (!pathSelected) {
          return;
        }
      }

      String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      String savePath = '$full_path/recording_$timestamp.mp4';
      print('path to file: $savePath');

      String command = "-rtsp_transport tcp -i $rtsplink -acodec copy -vcodec copy -y $savePath";

      setState(() {
        isRecording = true;
      });

      Fluttertoast.showToast(
          msg: "Запись началась",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 22.0
      );

      try{
        _recordingSession = await FFmpegKit.executeAsync(
          command,
              (ffmpeg_session.Session session) async {
            final returnCode = await session.getReturnCode();
            final output = await session.getOutput();
            print('output: $output');
            print('returnCode: $returnCode');

            if (mounted) {
              setState(() {
                isRecording = false;
              });
            }
          },
        );
      }
      catch(e){
        print('Error starting recording: $e');
        setState(() {
          isRecording = false;
        });
      }
    }
    else {
      if (_recordingSession != null) {
        await FFmpegKit.cancel();
        _recordingSession = null;

        Fluttertoast.showToast(
            msg: "Запись сохранена",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 22.0
        );
      }
      setState(() {
        isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    controllerforfield.dispose();
    player.dispose();
    _internetConnectionSteramSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                  child: _isPlayerInitialized
                      ? Video(controller: controller)
                      : Center(child: CircularProgressIndicator()),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.grey : Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: Size(200, 50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isRecording ? Icons.stop : Icons.play_arrow),
                      SizedBox(width: 12),
                      Text(
                        isRecording ? 'Остановить запись' : 'Начать запись',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: getSaveFilePath,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: Size(200, 50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder),
                      SizedBox(width: 12),
                      Text(  full_path.isEmpty ? 'Выбрать путь сохранения' : 'Поменять путь сохранения',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              )
            ],
          )) ,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () async {
          final link = await inputrtsp();
          if (link == null || link.isEmpty) {
            return;
          }
          else {
            String cleanedLink = link.trim();
            if (!cleanedLink.startsWith('rtsp://')) {
              showealert('Неправильная ссылка', 'Ссылка должна начинаться с rtsp://');
              return;
            }

            setState(() {
              rtsplink = cleanedLink;
            });
            await playerState();
            await _saveData(1);
            await insertIntoBD();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}