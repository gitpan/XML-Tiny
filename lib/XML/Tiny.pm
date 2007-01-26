package XML::Tiny;

use strict;

require Exporter;

use vars qw($VERSION @EXPORT_OK @ISA);

$VERSION = '1.0';
@EXPORT_OK = qw(parsefile);
@ISA = qw(Exporter);

$^W = 1;    # can't use warnings as that's a 5.6-ism

=head1 NAME

XML::Tiny - simple lightweight parser for a subset of XML

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

    if(ref($arg) eq '') { # we were passed a filename
        open(FH, $arg) || die(__PACKAGE__."::parsefile: Can't open $arg\n");
        $file = <FH>;
        close(FH);
    } else { $file = <$arg>; }
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
	    $token =~ /<(\S*)(.*)>/s; # my $attribs = $2;
	    $elem = { content => [], name => $1, type => 'e', parent => $elem };
	    push @{$elem->{parent}->{content}}, $elem;
	    # now handle self-closing tags
	    $elem = delete $elem->{parent} if($token =~ /\/>$/);
        } else {                          # ordinary content
	    # # $token =~ s/&#(\d+);/chr($1)/eg;
	    # # $token =~ s/&#x([A-F0-9]+);/chr(hex($1))/ieg;
	    $token =~ s/&lt;/</g;   $token =~ s/&gt;/>/g;
	    $token =~ s/&quot;/"/g; $token =~ s/&apos;/'/g;
	    # this translation *must* come last
	    $token =~ s/&amp;/&/g;
            push @{$elem->{content}}, { content => $token, type => 't' };
        }
    }
    die("Junk after end of document\n") if(exists($elem->{content}->[1]));
    die("No elements\n") if(!exists($elem->{content}->[0]));
    return $elem->{content};
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
L<XML::Parser::EasyTree>, with the exception that there is no support
for attributes, and hence no 'attrib' key in hashes.

If you find a document where that is not the case, please report it as
a bug.

=item With perl 5.004_05

The module is intended to be fully compatible with every version of perl
back to and including 5.004_05, and may be compatible with even older
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

=item CDATA and Attributes

Not handled at all and ignored.  However, a > character in CDATA or an
attribute will make the primitive parser think the document is malformed.

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

=head1 COPYRIGHT and LICENCE

Copyright 2007 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

'<one>zero</one>';
