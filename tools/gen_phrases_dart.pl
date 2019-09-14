#!/usr/bin/env perl
# This script creates the auto-generated phrases.dart file that contains
# all the phrase data.

sub make_phrase_list {
  my $id = "unknown";
  my @phrases;
  while(my $file = shift) {
    open my $fh, "<$file";
    while(my $phrase = <$fh>) {
      chomp $phrase;
      if($phrase =~ /^>>\s*(.*\S)/) {
        $id = $1;
      }
      next if $phrase =~ /^(>|#)/;
      next if $phrase =~ /^\s*$/;
      $phrase =~ s/'/\\'/g;
      $phrase = "'" . $phrase . "'";
      push @phrases, $phrase;
    }
    close $fh;
  }

  my @unique = keys { map { $_ => 1 } @phrases };
  my $output = "  \"$id\" : [\n    ";
  $output .= join ",\n    ", @unique;
  $output .= "\n  ]";
  return $output;
}

print <<END ;
/* phrases.dart */
/* This file is auto-generated.  Do not edit.  See tools/pre_build.pl. */

Map<String, List<String>> phraseData = {
END

@data = map { make_phrase_list($_) } <data/*dat>;
print join ",\n", @data;
print "\n};\n";
