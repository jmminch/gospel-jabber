# Gospel Jabber

A party guessing game targeted at members of the Church of Jesus Christ of
Latter-day Saints.

## Quick Start

If you just want to play the game, a live version is hosted at
[https://jmminch.github.io/gospel-jabber/](https://jmminch.github.io/gospel-jabber/).
While it is usable on a desktop/laptop, it is really intended for use on a
mobile device.

## About

The objective of Gospel Jabber is for one person to give verbal clues to get
their team mates to guess a secret word or phrase.  When playing
competitively, the game is played like "hot potato", where the team that was
attempting to guess the phrase when the time runs out loses the round.

This project was created both as a learning experience in simple web app
development, and also to create a fun activity for family gatherings, home
evenings, Sunday school, and so on.

## Coding

The game logic is written in Google's [Dart](https://www.dartlang.org)
language.  You will need the Dart SDK and webdev to compile the code.

If you have those tools, then after cloning the git repository, the process
to build the code is:

```
# pub get
# sh tools/pre_build.sh
# webdev build
# sh tools/post_build.sh
```

You can use `webdev serve` to serve the resulting page locally and access it
via your browser. Device mode in Chrome developer tools is handy for
emulating mobile-type behavior.
