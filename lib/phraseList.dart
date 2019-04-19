/* phraseList.dart */

import 'dart:html';
import 'dart:async';

/* The PhraseList class handles loading a list of phrases, and returning
 * them in a random order. */

class PhraseList {
  String source;
  bool loaded = false;
  String data;
  List<String> phrases;
  int index = 0;
  Function loadCompleteCallback;

  /* Load and parse a phrase list from a source URL.  The
   * loadCompleteCallback will run after the data is loaded and parsed. */
  PhraseList(this.source) {
    load();
  }

  /* Create a phrase list from an existing array of phrases. */
  PhraseList.fromList( List<String> input )
  {
    loaded = true;    

    /* Eliminate duplicates */
    phrases = input.toSet().toList();

    index = -1;

    if(loadCompleteCallback != null) {
      loadCompleteCallback();
      loadCompleteCallback = null;
    }
  }

  load( ) {
    HttpRequest.getString(source).then(
        (s) { data = s; loaded = true; parseData(); } );
  }

  parseData( ) {
    phrases = new List<String>();

    for( var s in data.split("\n") ) {
      s = s.trim(); /* remove leading/trailing whitespace */

      /* Skip blank lines, comments and topic markers */
      if(s.startsWith('>') ||
         s.startsWith('#') ||
         s.isEmpty) {
        continue;
      }

      phrases.add(s);
    }

    /* Eliminate duplicates */
    phrases = phrases.toSet().toList();

    index = -1;

    if(loadCompleteCallback != null) {
      loadCompleteCallback();
      loadCompleteCallback = null;
    }
  }

  /* Register a callback to run when the phrase data is ready.  It will run
   * immediately if the data is already ready. */
  onLoadComplete( Function callback ) {
    if(!loaded) {
      loadCompleteCallback = callback;
    } else {
      callback();
    }
  }

  /* Get the next random phrase.  This function shuffles the phrase list and
   * then iterates through it until reaching the end of the list, to ensure
   * that every phrase is picked once before starting over. */
  String randomPhrase( ) {
    if(index >= phrases.length || index < 0) {
      index = 0;
      phrases.shuffle();
    }

    return phrases[index++];
  }
}
