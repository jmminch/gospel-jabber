#!/usr/bin/env perl
# This script creates the auto-generated phrases.dart file that contains
# all the phrase data.

sub make_phrase_list {
  my $id = shift;
  my $output = "  \"$id\" : [\n    ";
  my @phrases;
  while(my $file = shift) {
    open my $fh, "<$file";
    while(my $phrase = <$fh>) {
      chomp $phrase;
      next if $phrase =~ /^(>|#)/;
      next if $phrase =~ /^\s*$/;
      $phrase =~ s/'/\\'/g;
      $phrase = "'" . $phrase . "'";
      push @phrases, $phrase;
    }
    close $fh;
  }

  my @unique = keys { map { $_ => 1 } @phrases };
  $output .= join ",\n    ", @unique;
  $output .= "\n  ]";
  return $output;
}

print <<END ;
/* phrases.dart */
/* This file is auto-generated.  Do not edit.  See tools/pre_build.pl. */

Map<String, List<String>> phraseData = {
END

print make_phrase_list("bible", "data/bible.dat"), ",\n";
print make_phrase_list("book_of_mormon", "data/book_of_mormon.dat"), ",\n";
print make_phrase_list("children", "data/children.dat"), ",\n";
print make_phrase_list("doctrine", "data/doctrine.dat"), ",\n";
print make_phrase_list("history", "data/history.dat"), ",\n";
print make_phrase_list("modern", "data/modern.dat"), ",\n";
print make_phrase_list("music", "data/music.dat"), "\n";
print "};\n";
