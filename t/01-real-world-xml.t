use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$@\n"); };

strip_attribs(my $easytree = do "t/amazon-parsed-with-xml-parser-easytree");
is_deeply(
    parsefile('t/amazon.xml'), $easytree,
    "Real-world XML from Amazon parsed correctly"
);

strip_attribs($easytree = do "t/rss-parsed-with-xml-parser-easytree");
is_deeply(
    parsefile('t/rss.xml'), $easytree,
    "Real-world XML from an RSS feed parsed correctly"
);
