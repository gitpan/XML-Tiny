package XML::Tiny;

use strict;

require Exporter;

use vars qw($VERSION @EXPORT_OK @ISA);

$VERSION = '1.02';
@EXPORT_OK = qw(parsefile);
@ISA = qw(Exporter);

$^W = 1;    # can't use warnings as that's a 5.6-ism

=head1 NAME

XML::Tiny - simple lightweight parser for a subset of XML

=head1 DESCRIPTION

XML::Tiny is a simple lightweight parser for a subset of XML

=head1 SYNOPSIS

    use XML::Tiny qw(parsefile);
    open($xmlfile, 'something.xml);
    my $document = parsefile($xmlfile);

=head1 FUNCTIONS

The C<parsefile> function is optionally exported.  By default nothing is
exported.  There is no objecty interface.

=over 4

=item parsefile

This takes exactly one parameter.  That may be:

=over 4

=item a filename

in which case the file is read and parsed;

=item a string of XML

in which case it is read and parsed.  How do we tell if we've got a string
or a filename?  If it begins with C<_TINY_XML_STRING_> then it's
a string.  That prefix is, of course, ignored when it comes to actually
parsing the data.  This is intended primarily for use by wrappers which
want to retain compatibility with Ye Aunciente Perl.  Normal users who want
to pass in a string would be expected to use L<IO::Scalar>.

=item a glob-ref or IO::Handle object

in which case again, the file is read and parsed.

=back

The former case is for compatibility with older perls, but makes no
attempt to properly deal with character sets.  If you open a file in a
character-set-friendly way and then pass in a handle / object, then the
method should Do The Right Thing as it only ever works with character
data.

=back

=cut

sub parsefile {
    my($arg, $file) = (+shift, '');
    local $/; # sluuuuurp

    if(ref($arg) eq '') { # we were passed a filename or a string
        if($arg =~ /^_TINY_XML_STRING_(.*)/) { # it's a string
            $file = $1;
        } else {
            open(FH, $arg) || die(__PACKAGE__."::parsefile: Can't open $arg\n");
            $file = <FH>;
            close(FH);
        }
    } else { $file = <$arg>; }
    die("No elements\n") if (!defined($file) || $file =~ /^\s*$/);
    # strip leading/trailing whitespace and comments (which don't nest - phew!)
    $file =~ s/^\s+|<!--.*?-->|\s+$//g;
    
    my $elem = { content => [] };

    # ignore empty tokens/whitespace tokens/processing instrs/entities/CDATA
    foreach my $token (grep { length && $_ !~ /^\s+$/ && $_ !~ /<[!?]/ }
      split(/(<[^>]+>)/, $file)) {
        if($token =~ m!</([^>]+)>!) {     # close tag
	    die("Not well-formed\n\tat $token\n") if($elem->{name} ne $1);
	    $elem = delete $elem->{parent};
        } elsif($token =~ m!<[^>]+>!) {   # open tag
	    my($tagname, $attribs_raw) = ($token =~ /<(\S*)(.*)>/s);
            # this makes the baby jesus cry
	    # first we pluck out double-quoted attribs,
	    # then single-quoted.
	    my $attrib  = {
	        $attribs_raw =~ /(\S+)\s*=\s*"([^"]*?)"/sg,
	        $attribs_raw =~ /(\S+)\s*=\s*'([^']*?)'/sg
	    };
	    foreach my $key (keys %{$attrib}) {
	        $attrib->{$key} = fixentities($attrib->{$key})
            }
	    $elem = {
                content => [],
                name => $tagname,
                type => 'e',
                attrib => $attrib,
                parent => $elem
            };
	    push @{$elem->{parent}->{content}}, $elem;
	    # now handle self-closing tags
	    $elem = delete $elem->{parent} if($token =~ /\/>$/);
        } else {                          # ordinary content
            $token = fixentities($token);
            push @{$elem->{content}}, { content => $token, type => 't' };
        }
    }
    die("Junk after end of document\n") if($#{$elem->{content}} > 0);
    die("No elements\n") if(
        $#{$elem->{content}} == -1 || $elem->{content}->[0]->{type} ne 'e'
    );
    return $elem->{content};
}

sub fixentities {
    my $thingy = shift;
    # # $thingy =~ s/&#(\d+);/chr($1)/eg;
    # # $thingy =~ s/&#x([A-F0-9]+);/chr(hex($1))/ieg;
    $thingy =~ s/&lt;/</g;
    $thingy =~ s/&gt;/>/g;
    $thingy =~ s/&quot;/"/g;
    $thingy =~ s/&apos;/'/g;
    # this translation *must* come last
    $thingy =~ s/&amp;/&/g;
    $thingy;
}

=head1 COMPATIBILITY

=over 4

=item With other modules

The C<parsefile> function is so named because it is intended to work in a
similar fashion to L<XML::Parser> with the L<XML::Parser::EasyTree> style.
Instead of saying this:

  use XML::Parser;
  use XML::Parser::EasyTree;
  $XML::Parser::EasyTree::Noempty=1;
  my $p=new XML::Parser(Style=>'EasyTree');
  my $tree=$p->parsefile('something.xml');

you would say:

  use XML::Tiny;
  my $tree = XML::Tiny::parsefile('something.xml');

Any document that can be parsed like that using XML::Tiny should
produce identical results if you use the above example of how to use
L<XML::Parser::EasyTree>.

If you find a document where that is not the case, please report it as
a bug.

=item With perl 5.004

The module is intended to be fully compatible with every version of perl
back to and including 5.004, and may be compatible with even older
versions of perl 5.

The lack of Unicode and friends in older perls means that XML::Tiny
does nothing with character sets.  If you have a document with a funny
character set, then you will need to open the file in an appropriate
mode using a character-set-friendly perl and pass the resulting file
handle to the module.

=item The subset of XML that we understand

The following parts of the XML standard are not handled at all or are
handled incorrectly:

=over 4

=item CDATA

Not handled at all and ignored.  However, a > character in CDATA
will make the primitive parser think the document is malformed.

=item Attributes

Handled, but the presence of a > character in an attribute will make the
parser think the document is malformed.  Attribute values may be either
double- or single- quoted.

=item DTDs and Schemas

This is not a validating parser.

=item Entities and references

In general, entities and references are not handled and so something like
C<&65;> will come through as the four characters C<&>, C<6>, C<5> and C<;>.
Naked ampersand characters are allowed.

C<&amp;>, C<&apos;>, C<&gt;>, C<&lt;> and C<&quot;> are, however,
supported.

=item Processing instructions (ie <?...>)

These are ignored.

=item Whitespace

We do not guarantee to correctly handle leading and trailing whitespace.

=back

=back

=head1 PHILOSOPHY and JUSTIFICATION

While feedback from real users about this module has been uniformly
positive and helpful, some people seem to take issue with this module
because it doesn't implement every last jot and tittle of the XML
standard and merely implements a useful subset.  A very useful subset,
as it happens, which can cope with common light-weight XML-ish tasks
such as parsing the results of queries to the Amazon Web Services.
Many, perhaps most, users of XML do not in fact need a full implementation
of the standard, and are understandably reluctant to install large complex
pieces of software which have many dependencies.  In fact, when they
realise what installing and using a full implementation entails, they
quite often don't *want* it.  Another class of users, people
distributing applications, often can not rely on users being able to
install modules from the CPAN, or even having tools like make or a shell
available.  XML::Tiny exists for those people.  Those people are *grateful*
that I have omitted rarely-used functionality in the interests of giving
them the bits that they need.

There has also been criticism of the module's name.  Apparently, if it
doesn't implement those jots and tittles I shouldn't defile the Sacred
Trigraph 'XML'.  Obviously, I do not subscribe to this view.  At no point
does the module even attempt to claim that it supports everything.  It is
perfectly clear to anyone who reads the documentation that it merely handles
a subset, and that if you need a full implementation you should look
elsewhere.  It does, however, contrary to some of the more frenzied of its
detractors, indeed implement a subset and not mere "tag soup" - unless XML
itself is mere "tag soup".  This is quite obvious when you look
at what it can do.  It can, for example, understand perfectly the subset
of XML used by the lovely people at Amazon to list what books are on my
wishlist.  If it couldn't do that, it wouldn't pass its own tests.

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary XML data, which demonstrates the bug.  Ideally, this
will be in the form of a file which I can drop in to the module's
test suite.  Please note that such files must work in perl 5.004_05,
and that mishandling of funny character sets, even on later versions
of perl, will not be considered a bug.

If you are feeling particularly generous you can encourage me in my
open source endeavours by buying me something from my wishlist:
  L<http://www.cantrell.org.uk/david/wishlist/>

=head1 SEE ALSO

L<XML::Parser>

L<XML::Parser::EasyTree>

L<http://beta.nntp.perl.org/group/perl.datetime/2007/01/msg6584.html>

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Thanks to David Romano for some compatibility patches for Ye Aunciente Perl;

Thanks to Matt Knecht and David Romano for prodding me to support attributes,
and to Matt for providing code to implement it in a quick n dirty minimal
kind of way.

=head1 COPYRIGHT and LICENCE

Copyright 2007 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

'<one>zero</one>';
