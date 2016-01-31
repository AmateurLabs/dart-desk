library desk;

import "dart:web_audio";
import "dart:html";
import "dart:async";

class Desk {
  AudioContext _ctx;
  AudioContext getContext() => _ctx;
  
  Desk() {
    _ctx = new AudioContext();
  }
}

class Channel {
  Desk desk;
  GainNode _gainNode;
  void set volume(num val) {
    _gainNode.gain.value = val;
  }
  num get volume => _gainNode.gain.value;
  
  Channel(Desk desk) {
    _gainNode = desk.getContext().createGain();
    _gainNode.gain.value = 1.0;
    _gainNode.connectNode(desk.getContext().destination);
  }
}

abstract class Sound {
  Desk desk;
  final Channel channel;
  
  Sound(this.desk, {this.channel});
}

class SoundFile extends Sound {
  AudioBuffer _buffer;
  bool get loaded => _loaded;
  bool _loaded = false;
  
  final String filename;
  SoundFile(Desk desk, this.filename, { Channel channel }) : super(desk, channel: channel) {
    HttpRequest.request(filename, responseType: 'arraybuffer').then((req) {
      desk._ctx.decodeAudioData(req.response).then((dataBuffer) {
        _buffer = dataBuffer;
        _loaded = true;
        _onLoad();
      });
    });
  }
  
  void play([num volume]) {
    volume ??= 1.0;
    num time = desk.getContext().currentTime;
    AudioBufferSourceNode _bufferNode = desk.getContext().createBufferSource();
    GainNode _gainNode = desk.getContext().createGain();
    _gainNode.gain.value = volume;
    if (channel != null)
      _gainNode.connectNode(channel._gainNode);
    else
      _gainNode.connectNode(desk.getContext().destination);
    _bufferNode.buffer = _buffer;
    _bufferNode.connectNode(_gainNode);
    _bufferNode.start(time);
  }
  
  void _onLoad(){}
}

class MusicFile extends SoundFile {
  AudioBufferSourceNode _bufferNode;
  GainNode _gainNode;
  void set volume(num val) {
    _gainNode.gain.value = val;
  }
  num get volume => _gainNode.gain.value;
  bool get playing => _playing;
  bool _playing = false;
  bool looping = false;
  
  MusicFile(Desk desk, String filename, { Channel channel }) : super(desk, filename, channel: channel) {
    _gainNode = desk.getContext().createGain();
    _gainNode.gain.value = 1.0;
    if (channel != null)
      _gainNode.connectNode(channel._gainNode);
    else
      _gainNode.connectNode(desk.getContext().destination);
  }
  
  AudioSource(Desk desk) {
    this.desk = desk;
  }
  
  void _onLoad() {
    if (playing) _play();
  }
  
  void play([num volume]) {
    if (volume != null) this.volume = volume;
    if (playing) return;
    _playing = true;
    if (loaded) _play();
  }
  
  void _play() {
    num time = desk.getContext().currentTime;
    _bufferNode = desk.getContext().createBufferSource();
    _bufferNode.buffer = _buffer;
    _bufferNode.loop = looping;
    _bufferNode.connectNode(_gainNode);
    _bufferNode.start(time);
    new Future.delayed(new Duration(microseconds: (_bufferNode.buffer.duration * Duration.MICROSECONDS_PER_SECOND).round()), () {
      if (!looping) stop();
    });
  }
  
  void restart() {
    stop();
    play();
  }
  
  void stop() {
    if (!playing) return;
    _playing = false;
    _stop();
  }
  
  void _stop() {
    num time = desk.getContext().currentTime;
    if (_bufferNode != null) _bufferNode.stop(time);
  }
}

class SoundWave extends Sound {
  WaveType type;
  num frequency;
  
  SoundWave(Desk desk, { this.type: WaveType.sine, this.frequency: 440.0, Channel channel }) : super(desk, channel: channel);
  
  void play(num duration, [num volume = 1.0]) {
    num time = desk.getContext().currentTime;
    OscillatorNode _oscillatorNode = desk.getContext().createOscillator();
    GainNode _gainNode = desk.getContext().createGain();
    _gainNode.gain.value = volume;
    if (channel != null)
      _gainNode.connectNode(channel._gainNode);
    else
      _gainNode.connectNode(desk.getContext().destination);
    _oscillatorNode.type = type.value;
    _oscillatorNode.frequency.value = frequency;
    _oscillatorNode.connectNode(_gainNode);
    _oscillatorNode.start(time);
    _oscillatorNode.stop(time + duration);
  }
}

class WaveType {
  final String value;
  
  const WaveType._const(this.value);
  
  static const WaveType sine = const WaveType._const("sine");
  static const WaveType square = const WaveType._const("square");
  static const WaveType sawtooth = const WaveType._const("sawtooth");
  static const WaveType triangle = const WaveType._const("triangle");
}