/* soundMgr.dart */

import 'dart:html';
import 'dart:async';

class SoundManager {
  Map<String, AudioElement> sounds;
  int loadCount = 0;
  Function loadCompleteCallback;

  SoundManager( ) {
    sounds = new Map<String, AudioElement>();
  }

  load( String key, String src ) {
    loadCount++;

    sounds[key] = new AudioElement(src);
    sounds[key].onCanPlayThrough.listen(soundLoaded);
  }

  soundLoaded( Event e ) {
    loadCount--;
    if(loadCount <= 0 && loadCompleteCallback != null) {
      loadCompleteCallback();
      loadCompleteCallback = null;
    }
  }

  onLoadComplete( Function callback ) {
    if(loadCount > 0) {
      loadCompleteCallback = callback;
    } else {
      callback();
    }
  }

  play( String key ) {
    if(sounds[key] != null) {
      sounds[key].currentTime = 0;
      if(sounds[key].paused) sounds[key]?.play();
    }
  }
}
