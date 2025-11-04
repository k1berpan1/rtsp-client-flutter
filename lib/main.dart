import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
// Add prefix to ffmpeg imports
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart' as ffmpeg_session;
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController controllerforfield;

  late final player = Player();
  late final controller = VideoController(player);
  String rtsplink = 'rtsp://rtspstream:z7zG6v7OVYaLYA8lCX3-f@zephyr.rtsp.stream/movie';
  bool isRecording = false;
  FFmpegSession? _recordingSession;

  @override
  void initState() {
    super.initState();
    controllerforfield = TextEditingController();
    playerState();
  }
  void playerState(){
    player.open(Media(rtsplink)).then((_) {
      print('Медиа успешно открыто');
    }).catchError((error) {
      print('Ошибка открытия медиа: $error');
    });
  }
  @override
  void dispose() {
    controllerforfield.dispose();
    player.dispose();
    super.dispose();
  }


 Future<String?> inputrtsp() => showDialog<String>(
   context: context,
   builder: (context) => AlertDialog(
     title: Text('Add rtsp'),
     content: TextField(
       autofocus: true,
       decoration: InputDecoration(hintText: 'rtsp'),
       controller: controllerforfield,
       onSubmitted: (_) => submit(),
     ),
     actions: [
       TextButton(
           onPressed: () => Navigator.pop(context, ''),
           child: Text('Cancel')
       ),
       TextButton(
           onPressed: submit,
           child: Text('Add')
       ),
     ]
   )
 );


  void submit() {
    Navigator.of(context).pop(controllerforfield.text);
    controllerforfield.clear();
  }

  Future<bool> _requestStoragePermission() async {
    var permissionGranted = await Permission.manageExternalStorage.request();
    return permissionGranted.isGranted;
  }

  void _toggleRecording() async {
    bool perm = await _requestStoragePermission();
    if (!perm) {
      Fluttertoast.showToast(
          msg: "Разрешение не предоставлено",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 22.0
      );
      return;
    }

    if (!isRecording) {
      Fluttertoast.showToast(
          msg: "Запись началась",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 22.0
      );

      String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      String full_path = '/storage/emulated/0/Download/recording_$timestamp.mp4';
      String command = "-rtsp_transport tcp -i $rtsplink -acodec copy -vcodec copy -y $full_path";

      setState(() {
        isRecording = true;
      });

      _recordingSession = await FFmpegKit.executeAsync(
        command,
            (ffmpeg_session.Session session) async { // Use the prefixed Session
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          if (mounted) {
            setState(() {
              isRecording = false;
            });
          }
        },
      );
    } else {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RTSP Video Recorder'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
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
              child: Video(controller: controller),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async{
          final link = await inputrtsp();
          if(link == null || link.isEmpty) {
            return;
          }
          else{
            setState(() => rtsplink = link);
            playerState();
          }
        }, child: Icon(Icons.add),),
    );
  }
}