import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._internal(){
    player.audioCache = AudioCache( prefix: 'asset/');
  }
  static final AudioManager instance = AudioManager._internal();

  final AudioPlayer player = AudioPlayer();

  bool isSoundEnabled = true;

  void setSoundEnabled(){
    isSoundEnabled = true;
  }
  void setSoundDisabled(){
    isSoundEnabled = false;
  }

  Future<void> playSoundWarningLeft() async {
    if(!isSoundEnabled) return;

    await player.play(
      AssetSource('sound/경고_왼쪽_다리.mp3'),
    );
  }

  Future<void> playSoundWarningRight() async {
    if(!isSoundEnabled) return;
    await player.play(
      AssetSource('sound/경고_오른쪽_다리.mp3'),
    );
  }

  Future<void> playSoundWarningBoth() async {
    if(!isSoundEnabled) return;
    await player.play(
      AssetSource('sound/경고_양쪽_다리.mp3'),
    );
  }
}