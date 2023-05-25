import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'
    show Codec, FlutterSoundPlayer, FlutterSoundRecorder;
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microphone Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Microphone Recorder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterSoundPlayer? _audioPlayer;
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _audioPath = '';

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer = FlutterSoundPlayer();
    _audioRecorder = FlutterSoundRecorder();

    try {
      if (_audioPlayer != null && _audioRecorder != null) {
        await _audioPlayer!.openAudioSession();
        await _audioRecorder!.openAudioSession();
      } else {
        throw Exception('Failed to initialize audio');
      }
    } catch (e) {
      print('Error initializing audio: $e');
      // Display an error message or handle the error appropriately
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!_isRecording && _audioRecorder != null) {
        await _audioRecorder!.startRecorder(
          toFile: 'path/to/audio.aac',
          codec: Codec.aacADTS,
        );

        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording && _audioRecorder != null) {
        // Add null check for _audioRecorder
        await _audioRecorder!.stopRecorder();

        setState(() {
          _isRecording = false;
        });

        if (_audioPath.isNotEmpty) {
          _uploadAudio(_audioPath);
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playAudio() async {
    try {
      if (!_isPlaying && _audioPath.isNotEmpty) {
        await _audioPlayer!.startPlayer(
          fromURI: _audioPath,
          codec: Codec.aacADTS,
        );

        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer!.stopPlayer();

        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> _uploadAudio(String audioPath) async {
    try {
      final file = File(audioPath);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5500/upload-audio/'),
      );

      request.files.add(await http.MultipartFile.fromPath('audio', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        print('Audio uploaded successfully');
      } else {
        print('Error uploading audio');
      }
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isRecording ? null : _startRecording,
              child: Text('Start Recording'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : null,
              child: Text('Stop Recording'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPlaying ? null : _playAudio,
              child: Text('Play Audio'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPlaying ? _stopAudio : null,
              child: Text('Stop Audio'),
            ),
          ],
        ),
      ),
    );
  }
}
