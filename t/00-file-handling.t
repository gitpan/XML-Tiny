use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
my $tests = $] >= 5.005003 ? 6 : 5;
print "1..$tests\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

eval { parsefile("t/non-existent-file"); };
ok($@ eq "XML::Tiny::parsefile: Can't open t/non-existent-file\n",
   "Raise error when asked to parse a non-existent file");

eval { parsefile('t/empty.xml'); };
ok($@ eq "No elements\n", "Empty files are an error");

is_deeply(
    parsefile('t/minimal.xml'),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => {} }],
    "Minimal file parsed correctly"
);

open(FOO, 't/minimal.xml');  # pass in a glob-ref
is_deeply(
    parsefile(\*FOO),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => {} }],
    "Passing a filehandle in a glob-ref works"
);
close(FOO);

if($] >= 5.005003) { # lexical filehandles! woo!
    open(my $foo, 't/minimal.xml');
    is_deeply(
        parsefile($foo),
	[{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => {} }],
	"Passing a lexical filehandle works"
    );
    close($foo);
}

is_deeply(
    parsefile('_TINY_XML_STRING_<x></x>'),
    parsefile('t/minimal.xml'),
    "Strings of XML work"
);
