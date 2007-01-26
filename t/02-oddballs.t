use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$@\n"); };

eval { parsefile('t/two-docs.xml'); };
ok($@ eq "Junk after end of document\n", "Fail if there's trailing crap");
