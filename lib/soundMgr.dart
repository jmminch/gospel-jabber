/* sound.dart */
/* Sound manager */

import "dart:html";
import "dart:web_audio";
import "dart:async";

class SoundManager {
  AudioContext cxt;
  Map<String, AudioBuffer> sounds = new Map<String, AudioBuffer>();

  Function loadCompleteCallback;

  int loadCount = 0;

  SoundManager( ) {
    cxt = new AudioContext();
  }

  load( String key, String src ) {
    loadCount++;

    var req = new HttpRequest();
    req.open("GET", src);
    req.responseType = "arraybuffer";

    /* The onLoad event doesn't seem to fire on iOS.  Use onReadyStateChange
     * instead. */
    req.onReadyStateChange.listen((e) {
      if(req.readyState == 4 && req.status == 200) {
       cxt.decodeAudioData(req.response)
        .then((buffer) { 
          sounds[key] = buffer; 
          loadCount--;
          if(loadCount <= 0 && loadCompleteCallback != null) {
            loadCompleteCallback();
            loadCompleteCallback = null;
          }
        });
      }
    });
    req.send();
  }

  onLoadComplete( Function cb ) {
    if(loadCount <= 0)
      cb();
    else
      loadCompleteCallback = cb;
  }

  play( String tag ) {
    if(sounds[tag] == null) return;
    AudioBufferSourceNode src = cxt.createBufferSource();
    src.buffer = sounds[tag];
    src.connectNode(cxt.destination);
    src.start(0);
  }
}

class SoundSprite {
  AudioContext cxt;
  AudioBuffer buffer;
  Map<String, List<num>> sprites = new Map<String, List<num>>();

  SoundSprite( this.cxt, this.buffer );

  addDef( String tag, num start, num duration ) {
    sprites[tag] = [start, duration];
  }

  play( String tag, { num at: 0.0 } ) {
    if(sprites[tag] == null) return;
    AudioBufferSourceNode src = cxt.createBufferSource();
    src.buffer = buffer;
    src.connectNode(cxt.destination);
    src.start(at, sprites[tag][0], sprites[tag][1]);
  }
}
