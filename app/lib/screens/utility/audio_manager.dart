import 'package:audioplayers/audioplayers.dart';


// 충격량 경고음성 관리
// 싱글톤
class AudioManager{
  AudioManager._internal();
  static final AudioManager instance = AudioManager._internal();

  late final player = AudioPlayer();

  void playSoundWarningLeft(){
    player.play(AssetSource('sound/경고_왼쪽_다리.mp3'));
  }

  void playSoundWarningRight(){
    player.play(AssetSource('sound/경고_오른쪽_다리.mp3'));
  }

  void playSoundWarningBoth(){
    player.play(AssetSource('sound/경고_양쪽_다리.mp3'));
  }

}