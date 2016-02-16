library desk;

import "dart:web_audio";
import "dart:html";
import "dart:async";
import "dart:math";

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
  
  void fadeOut([num duration = 0.5]) {
    num time = desk.getContext().currentTime;
    _gainNode.gain.cancelScheduledValues(time);
    _gainNode.gain.linearRampToValueAtTime(0.0, time+duration);
  }
  
  void fadeIn([num duration = 0.5]) {
    num time = desk.getContext().currentTime;
    _gainNode.gain.cancelScheduledValues(time);
    _gainNode.gain.linearRampToValueAtTime(1.0, time+duration);    
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

abstract class Note {
  static const num C0 = 8.175798915643707;
  static const num CS0 = 8.661957218027252;
  static const num D0 = 9.177023997418988;
  static const num DS0 = 9.722718241315029;
  static const num E0 = 10.300861153527183;
  static const num F0 = 10.913382232281373;
  static const num FS0 = 11.562325709738575;
  static const num G0 = 12.249857374429663;
  static const num GS0 = 12.978271799373287;
  static const num A0 = 13.75;
  static const num AS0 = 14.567617547440307;
  static const num B0 = 15.433853164253883;
  static const num C1 = 16.351597831287414;
  static const num CS1 = 17.323914436054505;
  static const num D1 = 18.354047994837977;
  static const num DS1 = 19.445436482630058;
  static const num E1 = 20.601722307054366;
  static const num F1 = 21.826764464562746;
  static const num FS1 = 23.12465141947715;
  static const num G1 = 24.499714748859326;
  static const num GS1 = 25.956543598746574;
  static const num A1 = 27.5;
  static const num AS1 = 29.13523509488062;
  static const num B1 = 30.86770632850775;
  static const num C2 = 32.70319566257483;
  static const num CS2 = 34.64782887210901;
  static const num D2 = 36.70809598967594;
  static const num DS2 = 38.890872965260115;
  static const num E2 = 41.20344461410875;
  static const num F2 = 43.653528929125486;
  static const num FS2 = 46.2493028389543;
  static const num G2 = 48.999429497718666;
  static const num GS2 = 51.91308719749314;
  static const num A2 = 55;
  static const num AS2 = 58.27047018976124;
  static const num B2 = 61.7354126570155;
  static const num C3 = 65.40639132514966;
  static const num CS3 = 69.29565774421802;
  static const num D3 = 73.41619197935188;
  static const num DS3 = 77.78174593052023;
  static const num E3 = 82.4068892282175;
  static const num F3 = 87.30705785825097;
  static const num FS3 = 92.4986056779086;
  static const num G3 = 97.99885899543733;
  static const num GS3 = 103.82617439498628;
  static const num A3 = 110;
  static const num AS3 = 116.54094037952248;
  static const num B3 = 123.47082531403103;
  static const num C4 = 130.8127826502993;
  static const num CS4 = 138.59131548843604;
  static const num D4 = 146.8323839587038;
  static const num DS4 = 155.56349186104046;
  static const num E4 = 164.81377845643496;
  static const num F4 = 174.61411571650194;
  static const num FS4 = 184.9972113558172;
  static const num G4 = 195.99771799087463;
  static const num GS4 = 207.65234878997256;
  static const num A4 = 220;
  static const num AS4 = 233.08188075904496;
  static const num B4 = 246.94165062806206;
  static const num C5 = 261.6255653005986;
  static const num CS5 = 277.1826309768721;
  static const num D5 = 293.6647679174076;
  static const num DS5 = 311.12698372208087;
  static const num E5 = 329.6275569128699;
  static const num F5 = 349.2282314330039;
  static const num FS5 = 369.9944227116344;
  static const num G5 = 391.99543598174927;
  static const num GS5 = 415.3046975799451;
  static const num A5 = 440;
  static const num AS5 = 466.1637615180899;
  static const num B5 = 493.8833012561241;
  static const num C6 = 523.2511306011972;
  static const num CS6 = 554.3652619537442;
  static const num D6 = 587.3295358348151;
  static const num DS6 = 622.2539674441618;
  static const num E6 = 659.2551138257398;
  static const num F6 = 698.4564628660078;
  static const num FS6 = 739.9888454232688;
  static const num G6 = 783.9908719634985;
  static const num GS6 = 830.6093951598903;
  static const num A6 = 880;
  static const num AS6 = 932.3275230361799;
  static const num B6 = 987.7666025122483;
  static const num C7 = 1046.5022612023945;
  static const num CS7 = 1108.7305239074883;
  static const num D7 = 1174.6590716696303;
  static const num DS7 = 1244.5079348883237;
  static const num E7 = 1318.5102276514797;
  static const num F7 = 1396.9129257320155;
  static const num FS7 = 1479.9776908465376;
  static const num G7 = 1567.981743926997;
  static const num GS7 = 1661.2187903197805;
  static const num A7 = 1760;
  static const num AS7 = 1864.6550460723597;
  static const num B7 = 1975.533205024496;
  static const num C8 = 2093.004522404789;
  static const num CS8 = 2217.4610478149766;
  static const num D8 = 2349.31814333926;
  static const num DS8 = 2489.0158697766474;
  static const num E8 = 2637.02045530296;
  static const num F8 = 2793.825851464031;
  static const num FS8 = 2959.955381693075;
  static const num G8 = 3135.9634878539946;
  static const num GS8 = 3322.437580639561;
  static const num A8 = 3520;
  static const num AS8 = 3729.3100921447194;
  static const num B8 = 3951.066410048992;
  static const num C9 = 4186.009044809578;
  static const num CS9 = 4434.922095629953;
  static const num D9 = 4698.63628667852;
  static const num DS9 = 4978.031739553295;
  static const num E9 = 5274.04091060592;
  static const num F9 = 5587.651702928062;
  static const num FS9 = 5919.91076338615;
  static const num G9 = 6271.926975707989;
  static const num GS9 = 6644.875161279122;
  static const num A9 = 7040;
  static const num AS9 = 7458.620184289437;
  static const num B9 = 7902.132820097988;
  static const num C10 = 8372.018089619156;
  static const num CS10 = 8869.844191259906;
  static const num D10 = 9397.272573357044;
  static const num DS10 = 9956.06347910659;
  static const num E10 = 10548.081821211836;
  static const num F10 = 11175.303405856126;
  static const num FS10 = 11839.8215267723;
  static num midiNoteToFrequency(int m) => pow(2, (m-69)/12) * 440.0;
}