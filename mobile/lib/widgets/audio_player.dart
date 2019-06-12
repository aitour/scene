import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;

  AudioPlayerWidget({Key key, this.url}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool hasError = false;
  Duration duration = new Duration(hours: 0, minutes: 0, seconds: 0),
      position = new Duration(hours: 0, minutes: 0, seconds: 0);
  AudioPlayer audioPlayer = new AudioPlayer();

  @override
  void initState() {
    super.initState();

    audioPlayer.audioPlayerStateChangeHandler = (state) {
      setState(() {});
    };

    audioPlayer.durationHandler = (Duration d) {
      print('Max duration: $d');
      setState(() {
        duration = d;
      });
    };

    audioPlayer.positionHandler = (Duration p) {
      print('Current position: $p');
      setState(() {
        position = p;
      });
    };

    audioPlayer.errorHandler = (msg) {
      print('audioPlayer error : $msg');
      setState(() {
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    };
  }

  void buttonPressed() async {
    try {
      if (audioPlayer.state == null || audioPlayer.state == AudioPlayerState.STOPPED) {
        await this.audioPlayer.play(this.widget.url);
      } else if (audioPlayer.state == AudioPlayerState.PLAYING) {
        await this.audioPlayer.pause();
      } else if (audioPlayer.state == AudioPlayerState.PAUSED) {
        await this.audioPlayer.resume();
      } else if (audioPlayer.state == AudioPlayerState.COMPLETED) {
        await this.audioPlayer.seek(Duration());
        await this.audioPlayer.resume();
      }
    } on PlatformException catch (e) {
      print("play ${this.widget.url} error: $e");
      hasError = true;
    }
    setState(() {});
  }

  String prossText() {
    if (position.inSeconds == 0 || duration.inSeconds == 0) {
      return "--/--";
    }

    var timeLeft = duration.inSeconds - position.inSeconds;
    var timeLeftMinutes = timeLeft ~/ 60;
    var timeLeftSeconds = timeLeft - timeLeftMinutes * 60;
    var durseconds = duration.inSeconds - duration.inMinutes * 60;
    return "$timeLeftMinutes''$timeLeftSeconds'/${duration.inMinutes}''$durseconds'";
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = hasError ? Colors.grey : Colors.black;
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
              child: Slider(
            min: 0.0,
            max: 1.0,
            value: position.inSeconds == 0 || duration.inSeconds == 0
                ? 0
                : position.inSeconds / duration.inSeconds,
                onChanged: audioPlayer == null ? null : (double val) => audioPlayer.seek(Duration(hours:0, minutes:0, seconds: (val * duration.inSeconds).toInt())),
          )),
          Text(prossText()),
          FlatButton(
            child: audioPlayer.state != AudioPlayerState.PLAYING
                ? Icon(Icons.play_arrow, color: iconColor)
                : Icon(Icons.pause, color: iconColor),
            onPressed: buttonPressed,
          ),
        ],
      ),
    );
  }
}
