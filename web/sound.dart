/* sound.dart */
/* Sound system test */

import "dart:html";
import "dart:web_audio";
import "dart:async";
import "dart:math";

import "package:jabber/sound.dart";

SoundManager mgr;
SoundSprite sprite;
Random rng;

class GameTimer {
  bool sound = false;
  Function onComplete;
  Timer iTimer;
  Timer uTimer;

  num nextScheduledTime;
  num phase0End;
  num phase1End;
  num phase2End;
  num endTime;

  GameTimer( int duration, { this.sound, this.onComplete } ) {
    iTimer = new Timer(new Duration(seconds: duration), timeUp);

    if(sound) {
      nextScheduledTime = mgr.cxt.currentTime;
      double d = duration.toDouble();

      /* The timer beep runs in 4 phases (0-3).  Phase 3 takes a random amount
       * of time from 5-10 seconds, so that you can't be sure how much time you
       * have left when it starts.  The remaining phases are carved up as
       * 50% for phase 0, 25% for phase 1, and 25% for phase 2. */

      double p3 = rng.nextDouble() * 5.0 + 5.0;
      double p0 = (d - p3) * 0.5;
      double p1 = p0 * 0.5;
      double p2 = p1;

      phase0End = mgr.cxt.currentTime + p0;
      phase1End = phase0End + p1;
      phase2End = phase1End + p2;
      endTime = mgr.cxt.currentTime + d;

      soundUpdate();
    }
  }

  soundUpdate( ) {
    num delay = 2.0;
    uTimer = null;

    if(mgr.cxt.currentTime > endTime) {
      return;
    } else if(mgr.cxt.currentTime > phase2End) {
      delay = 0.12;
    } else if(mgr.cxt.currentTime > phase1End) {
      delay = 0.25;
    } else if(mgr.cxt.currentTime > phase0End) {
      delay = 0.5;
    } else {
      delay = 2.0;
    }

    while(nextScheduledTime < mgr.cxt.currentTime + 1.25) {
      if(nextScheduledTime >= mgr.cxt.currentTime &&
         nextScheduledTime < endTime) {
        sprite.play("tick", at: nextScheduledTime);
      }

      nextScheduledTime += delay;
    }

    if(nextScheduledTime < endTime) {
      uTimer = new Timer(new Duration(seconds: 1), soundUpdate);
    }
  }

  cancel( ) {
    uTimer?.cancel();
    iTimer?.cancel();
  }

  timeUp( ) {
    if(sound) {
      sprite.play("horn");
    }

    uTimer?.cancel();

    if(onComplete != null) onComplete();
  }
}

main( ) {
  rng = new Random();
  querySelector("#start").onClick.listen(start);
  mgr = new SoundManager();
  mgr.load("gamesound",
      "audio/game_sounds.mp3");
  mgr.onLoadComplete(() {
    sprite = new SoundSprite(mgr.cxt, mgr.sounds["gamesound"]);
    sprite.addDef("tick", 0.0, 0.15);
    sprite.addDef("horn", 0.5, 2.0);
    sprite.addDef("next", 3.0, 0.300);
  });
}

start( MouseEvent e ) {
  new GameTimer(35 + rng.nextInt(26), sound: true);
}
