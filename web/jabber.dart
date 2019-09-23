/* jabber.dart */

import "dart:html";
import "dart:async";
import "dart:math";

import "package:jabber/phraseList.dart";
import "package:jabber/soundMgr.dart";

import "phrases.dart";

Random rng;
PhraseList phrases;
SoundManager soundMgr;
SoundSprite sprite;
bool gameActive = false;
String histState;
GameTimer gameTimer;
int score1 = 0;
int score2 = 0;

BeforeInstallPromptEvent installPrompt = null;
/* Counters used to decide when to trigger the install prompt. */
int roundCount = 0;
int phraseCount = 0;

main( ) {
  rng = new Random();

  /* Set up listeners. */
  querySelector("#option-start").onClick.listen(startClicked);
  querySelector("#option-help").onClick.listen(optionButtonClicked);
  querySelector("#option-about").onClick.listen(optionButtonClicked);
  querySelector("#option-install").onClick.listen(optionButtonClicked);

  querySelector("#game-next").onClick.listen(nextClicked);
  querySelector("#game-timeout-continue").onClick.listen(continueClicked);
  querySelector("#team1-score").onClick.listen(score1Clicked);
  querySelector("#team2-score").onClick.listen(score2Clicked);

  querySelector("#game-back-t").onClick.listen(backClicked);
  querySelector("#help-back-t").onClick.listen(backClicked);
  querySelector("#about-back-t").onClick.listen(backClicked);
  querySelector("#install-back-t").onClick.listen(backClicked);

  querySelector("#game-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#help-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#about-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#install-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#game-timeout-popup").on['transitionend'].listen(subScreenAnimEnd);

  window.onPopState.listen(popState);

  window.on['beforeinstallprompt'].listen(beforeInstallPrompt);

  /* option screen starts hidden because it takes a second or so to spin up
   * a dart script.  This ensures that the page is ready to go when the
   * interface is displayed. */
  setOptions();
  DivElement optionScreen = querySelector("#option-screen");
  optionScreen.style.visibility = "visible";
  optionScreen.style.opacity = "1.0";
}

/* set the state of the options radio buttons based on what was saved in
 * local storage. */
setOptions( ) {
  if(window.localStorage['phraseList'] != null) {
    for(var e in document.getElementsByName('list')) {
      RadioButtonInputElement r = e;
      if(r.value == window.localStorage['phraseList']) {
        r.checked = true;
        break;
      }
    }
  }

  if(window.localStorage['gameMode'] != null) {
    for(var e in document.getElementsByName('mode')) {
      RadioButtonInputElement r = e;
      if(r.value == window.localStorage['gameMode']) {
        r.checked = true;
        break;
      }
    }
  }

  if(window.localStorage['hard'] != null) {
    CheckboxInputElement check = querySelector("#difficult");
    check.checked = (window.localStorage['hard'] == "true");
  }
}

/* transition from the options screen to a subscreen */
slideIn( DivElement elem )
{
  elem.style.transform = "translateX(0)";
  elem.style.visibility = "visible";
  DivElement optionScreen = querySelector("#option-screen");
  optionScreen.style.opacity = "0";
}

slideOut( DivElement elem )
{
  elem.style.transform = "translateX(100%)";
  DivElement optionScreen = querySelector("#option-screen");
  optionScreen.style.opacity = "1.0";
}

subScreenAnimEnd( Event e )
{
  Element elem = e.target;
  if(elem.style.opacity == "0" ||
     elem.style.transform == "translateX(100%)") {
    elem.style.visibility = "hidden";
  }
}

/* Called when the 'back' button is pressed.  If we're on a sub-screen, then
 * we want to go back to the main options screen rather than exiting. */
popState( PopStateEvent e ) {
  switch(histState) {
    case 'help':
      slideOut(querySelector("#help-screen"));
      break;
    case 'about':
      slideOut(querySelector("#about-screen"));
      break;
    case 'install':
      slideOut(querySelector("#install-screen"));
      break;
    case 'game':
      /* transition back to option screen */
      slideOut(querySelector("#game-screen"));

      /* stop the game. */
      gameTimer?.cancel();

      /* Make sure that the timeout div is hidden. */
      DivElement timeoutDiv = querySelector("#game-timeout-popup");
      if(timeoutDiv.style.visibility != "hidden")
        continueClicked(null);

      break;
  }

  histState = null;
}

/* generic function for clicking a back button in a sub-screen. */
backClicked( MouseEvent e ) {
  window.history.back();
  popState(null);
}

optionButtonClicked( MouseEvent ev )
{
  Element e = ev.target;
  var id = e.id.substring(7);  /* cut off the leading "option-" */

  if(id == "install" && installPrompt != null) {
    /* We can display the install prompt directly; do that. */
    installPrompt.prompt();
    installPrompt = null;
    return;
  }

  /* transition to the appropriate subscreen */
  DivElement subScreen = querySelector("#" + id + "-screen");
  slideIn(subScreen);

  /* Update window history */
  window.history.pushState(id, null, null);
  histState = id;
}

startClicked( MouseEvent e ) {
  /* Load all sounds. */
  soundMgr = new SoundManager();
  soundMgr.load("gamesound", "audio/game_sounds.mp3");
  soundMgr.onLoadComplete(() {
    sprite = new SoundSprite(soundMgr.cxt, soundMgr.sounds["gamesound"]);
    sprite.addDef("tick", 0.0, 0.15);
    sprite.addDef("buzzer", 0.24, 1.45);
    sprite.addDef("next", 1.79, 0.2);
  });

  /* save options to local storage */
  for(var e in document.getElementsByName('list')) {
    RadioButtonInputElement r = e;
    if(r.checked) {
      window.localStorage['phraseList'] = r.value;
      
      /* find the associated label and set that as the topic. */
      for(var e in document.getElementsByTagName('label')) {
        LabelElement l = e;
        if(l.htmlFor == r.id) {
          window.localStorage['phraseListName'] = l.text;
        }
      }

      break;
    }
  }

  for(var e in document.getElementsByName('mode')) {
    RadioButtonInputElement r = e;
    if(r.checked) {
      window.localStorage['gameMode'] = r.value;
      break;
    }
  }

  CheckboxInputElement check = querySelector("#difficult");
  window.localStorage['hard'] = check.checked ? "true" : "false";

  /* set topic text */
  DivElement topicText = querySelector("#game-topic-text");
  topicText.text = window.localStorage['phraseListName'];

  /* clear out the phrase area */
  DivElement curElem = querySelector("#game-cur-phrase");
  curElem.setInnerHtml('');

  /* load the appropriate phrase list.
   * This used to load a phrase file using HTTP, but that means that you
   * have to handle delays and errors.  Now the phrases are compiled into
   * the script in the phrases.dart file, which is auto-generated before
   * building. */
  var phraseSrc = window.localStorage['phraseList'];
  if(phraseSrc == null) phraseSrc = "everything";

  if(phraseData[phraseSrc] == null) phraseSrc = "everything";

  List<String> l;

  if(phraseSrc == "everything") {
    l = new List<String>();
    phraseData.forEach((k, v) { if(k != "simple") l.addAll(v); } );
  } else {
    l = new List<String>.from(phraseData[phraseSrc]);
  }

  /* The entries in the list may be prefixed with some flags:
     '*' means that the entry is "difficult," and should be removed if the
       hard setting is disabled.
     '+' means that the entry should not be included in the "All topics"
       list (because it is too topic-specific.)
    Search for any marked terms and eliminate them if appropriate, or remove
    the flag characters otherwise. */
  for(var i = 0; i < l.length; i++) {
    String c;
    do {
      c = l[i].substring(0, 1);
      if(c == "*" || c == "+") {
        if((c == "*" && window.localStorage['hard'] != "true") ||
           (c == "+" && phraseSrc == "everything")) {
          /* Eliminate this entry. */
          l.removeAt(i);
          i--;
          break;
        }

        /* Remove the leading flag character */
        l[i] = l[i].substring(1);
      }
    } while(c == "*" || c == "+");
  }

  phrases = new PhraseList.fromList(l);

  /* do initial game setup */
  gameActive = false;
  score1 = 0;
  score2 = 0;

  roundCount = 0;
  phraseCount = 0;

  DivElement gameScreen = querySelector("#game-screen");
  slideIn(gameScreen);

  window.history.pushState("game", null, null);
  histState = "game";

  soundMgr.cxt.resume();
}

nextClicked( MouseEvent e ) {
  DivElement curElem = querySelector("#game-cur-phrase");
  DivElement nextElem = querySelector("#game-next-phrase");

  /* Animated transition to the new phrase */
  curElem.style.animation = "slide-fade-out 0.3s forwards";
  nextElem.style.animation = "slide-fade-in 0.3s forwards";

  /* Set next phrase */
  nextElem.setInnerHtml(phrases.randomPhrase());

  /* Swap the current and next phrase elements. */
  curElem.id = "game-next-phrase";
  nextElem.id = "game-cur-phrase";

  sprite?.play("next");

  /* If this was the first time the next button was pressed, record that the
   * game is now active and start the timer. */
  if(!gameActive) {
    gameActive = true;
    roundCount++;
    phraseCount = 0;

    /* Time range 35-60 seconds */
    if(window.localStorage['gameMode'] == 'silent') {
      gameTimer = new GameTimer(35 + rng.nextInt(26), sound: false,
                                onComplete: gameTimeout);
    } else if(window.localStorage['gameMode'] == 'normal') {
      gameTimer = new GameTimer(35 + rng.nextInt(26), sound: true,
                                onComplete: gameTimeout);
    }
  } else {
    phraseCount++;
    /* In casual mode, trigger the install prompt after 20 phrases rather
     * than 3 rounds. */
    if(installPrompt != null && window.localStorage['gameMode'] == 'casual' &&
       phraseCount > 20) {
      installPrompt.prompt();
      installPrompt = null;
    }
  }
}

gameTimeout( ) {
  gameActive = false;

  gameTimer?.cancel();
  gameTimer = null;

  sprite?.play("buzzer");

  updateScore();

  DivElement timeoutDiv = querySelector("#game-timeout-popup");
  timeoutDiv.style.visibility = "visible";
  timeoutDiv.style.opacity = "1.0";
}

updateScore( ) {
  DivElement scoreElem = querySelector("#game-timeout-team1-score");
  scoreElem.setInnerHtml(score1.toString());
  scoreElem = querySelector("#game-timeout-team2-score");
  scoreElem.setInnerHtml(score2.toString());
}

continueClicked( MouseEvent e ) {
  /* Animated fade out. */
  DivElement timeoutDiv = querySelector("#game-timeout-popup");
  timeoutDiv.style.opacity = "0";

  DivElement curElem = querySelector("#game-cur-phrase");
  curElem.setInnerHtml('');

  /* If we can trigger the install prompt, do it after 3 rounds of play.  At
   * that point people can probably decide if they're interested or not. */
  if(installPrompt != null && roundCount >= 3) {
    installPrompt.prompt();
    installPrompt = null;
  }
}

score1Clicked( MouseEvent e ) {
  score1++;
  updateScore();
}

score2Clicked( MouseEvent e ) {
  score2++;
  updateScore();
}

class GameTimer {
  bool sound = false;
  Function onComplete;
  Timer iTimer;  /* overall timer */
  Timer uTimer;  /* sound update timer */

  num nextScheduledTime;
  num phase0End;
  num phase1End;
  num phase2End;
  num endTime;

  GameTimer( int duration, { this.sound, this.onComplete } ) {
    iTimer = new Timer(new Duration(seconds: duration), timeUp);

    if(sound) {
      /* Time for first tick. */
      nextScheduledTime = soundMgr.cxt.currentTime + 2.0;
      double d = duration.toDouble();

      /* The timer beep runs in 4 phases (0-3).  Phase 3 takes a random amount
       * of time from 5-10 seconds, so that you can't be sure how much time you
       * have left when it starts.  The remaining phases are carved up as
       * 50% for phase 0, 25% for phase 1, and 25% for phase 2. */

      double p3 = rng.nextDouble() * 5.0 + 5.0;
      double p0 = (d - p3) * 0.5;
      double p1 = p0 * 0.5;
      double p2 = p1;
      phase0End = soundMgr.cxt.currentTime + p0;
      phase1End = phase0End + p1;
      phase2End = phase1End + p2;
      endTime = soundMgr.cxt.currentTime + d;

      soundUpdate();
    }
  }

  soundUpdate( ) {
    num delay = 2.0;
    uTimer = null;

    if(soundMgr.cxt.currentTime > endTime) {
      return;
    } else if(soundMgr.cxt.currentTime > phase2End) {
      delay = 0.2;
    } else if(soundMgr.cxt.currentTime > phase1End) {
      delay = 0.4;
    } else if(soundMgr.cxt.currentTime > phase0End) {
      delay = 0.7;
    } else {
      delay = 2.0;
    }

    /* This function runs once a second.  Schedule all sounds to play for
     * the next 1.25 seconds. */
    while(nextScheduledTime < soundMgr.cxt.currentTime + 1.25) {
      if(nextScheduledTime >= soundMgr.cxt.currentTime &&
         nextScheduledTime < endTime) {
        sprite?.play("tick", at: nextScheduledTime);
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
    uTimer?.cancel();

    if(onComplete != null) onComplete();
  }
}

/* Tells us that we can trigger an installation popup automatically.
 * Don't want to do it too early, but I also want people to be aware of it --
 * so it will display the prompt either when you press "add to home screen"
 * or after three rounds of gameplay. */
beforeInstallPrompt( Event ev ) {
  installPrompt = ev;
  installPrompt.preventDefault();
}
