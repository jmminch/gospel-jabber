/* phraseList.dart */

/* The PhraseList class handles loading a list of phrases, and returning
 * them in a random order. */

class PhraseList {
  List<String> phrases;
  int index = 0;

  /* Create a phrase list from an existing array of phrases. */
  PhraseList.fromList( List<String> input )
  {
    /* Eliminate duplicates */
    phrases = input.toSet().toList();

    index = -1;
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
