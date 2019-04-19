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
bool gameActive = false;
Timer gameTimer;
String histState;

main( ) {
  rng = new Random();

  /* Load all sounds.
   * Note that this starts as soon as the page is loaded (displaying the
   * options screen), so that the sounds will hopefully be loaded before the
   * user starts a game. */
  soundMgr = new SoundManager();
  soundMgr.load("next", "audio/zapsplat_multimedia_game_menu_tone_053_25468.mp3");
  soundMgr.load("timeup", "audio/zapsplat_multimedia_game_show_buzzer_001_27373.mp3");

  /* Set up listeners. */
  querySelector("#option-start").onClick.listen(startClicked);
  querySelector("#option-help").onClick.listen(helpClicked);
  querySelector("#option-about").onClick.listen(aboutClicked);
  querySelector("#option-install").onClick.listen(installClicked);

  querySelector("#game-next").onClick.listen(nextClicked);
  querySelector("#game-timeout-continue").onClick.listen(continueClicked);

  querySelector("#game-back-t").onClick.listen(backClicked);
  querySelector("#help-back-t").onClick.listen(backClicked);
  querySelector("#about-back-t").onClick.listen(backClicked);
  querySelector("#install-back-t").onClick.listen(backClicked);

  DivElement elem = querySelector("#option-screen");

  querySelector("#game-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#help-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#about-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#install-screen").on['transitionend'].listen(subScreenAnimEnd);
  querySelector("#game-timeout-popup").on['transitionend'].listen(subScreenAnimEnd);

  window.onPopState.listen(popState);

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

helpClicked( MouseEvent e ) {
  /* transition to the help screen */
  DivElement helpScreen = querySelector("#help-screen");
  slideIn(helpScreen);

  window.history.pushState("help", null, null);
  histState = "help";
}

aboutClicked( MouseEvent e ) {
  /* transition to the about screen */
  DivElement aboutScreen = querySelector("#about-screen");
  slideIn(aboutScreen);

  window.history.pushState("about", null, null);
  histState = "about";
}

installClicked( MouseEvent e ) {
  /* transition to the install screen */
  DivElement installScreen = querySelector("#install-screen");
  slideIn(installScreen);

  window.history.pushState("install", null, null);
  histState = "install";
}

startClicked( MouseEvent e ) {
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

  if(phraseSrc == "everything") {
    /* Generate a list from the concatenation of all phrase lists except
     * the "children" list. */
    List<String> l = new List<String>();
    phraseData.forEach((k, v) { if(k != "children") l.addAll(v); });
    phrases = new PhraseList.fromList(l);
  } else {
    phrases = new PhraseList.fromList(phraseData[phraseSrc]);
  }

  /* do initial game setup */
  gameActive = false;

  DivElement gameScreen = querySelector("#game-screen");
  slideIn(gameScreen);

  window.history.pushState("game", null, null);
  histState = "game";
}

nextClicked( MouseEvent e ) {
  /* If the phrase list isn't loaded yet, it should be really soon.  Cue up
   * a request to display the first phrase as soon as it's done. */
  if(!phrases.loaded) {
    phrases.onLoadComplete(() => nextClicked(null));
    return;
  }

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

  soundMgr.play("next");

  /* If this was the first time the next button was pressed, record that the
   * game is now active and start the timer. */
  if(!gameActive) {
    gameActive = true;
    /* Time range 35-60 seconds */
    if(window.localStorage['gameMode'] == 'traditional') {
       gameTimer = 
          new Timer(new Duration(seconds: (35 + rng.nextInt(26))), gameTimeout);
    }
  }
}

gameTimeout( ) {
  gameActive = false;
  gameTimer = null;

  DivElement timeoutDiv = querySelector("#game-timeout-popup");
  timeoutDiv.style.visibility = "visible";
  timeoutDiv.style.opacity = "1.0";

  soundMgr.play("timeup");
}

continueClicked( MouseEvent e ) {
  /* Animated fade out. */
  DivElement timeoutDiv = querySelector("#game-timeout-popup");
  timeoutDiv.style.opacity = "0";

  DivElement curElem = querySelector("#game-cur-phrase");
  curElem.setInnerHtml('');
}
