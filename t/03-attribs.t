use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..1\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x a="A" b="B &amp; C"/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { a => 'A', b => 'B & C' }}],
    "Attributes parsed correctly"
);
