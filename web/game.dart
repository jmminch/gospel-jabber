/* game.dart */

import "dart:html";

main( ) {
  /* Set up handlers for the various buttons. */
  ButtonElement nextButton = querySelector("#nextButton");
  print(nextButton);
  nextButton.onClick.listen(nextClicked);
}

nextClicked( MouseEvent e ) {
  window.alert("Clicked next!");
}
