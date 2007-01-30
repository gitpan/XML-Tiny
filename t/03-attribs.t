use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..3\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x a="A" b="B &amp; C"/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { a => 'A', b => 'B & C' }}],
    "Double-quoted attributes parsed correctly"
);

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x a='A' b='B &amp; C'/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { a => 'A', b => 'B & C' }}],
    "Single-quoted attributes parsed correctly"
);

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x single = '"' double = "'"/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { single => '"', double => "'" }}],
    "Quoted quotes in attributes parsed correctly"
);
