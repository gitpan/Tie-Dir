#

package Tie::Dir;

=head1 NAME

Tie::Dir - class definition for reading directories via a tied hash

=head1 SYNOPSIS

	tie %hash, Tie::Dir, ".";

	new Tie::Dir \%hash, ".";

	$hash = new Tie::Dir ".";

	# itterate through the directory
	foreach $file ( keys %hash ) {
		...
	}

	# Set the access and modification times (touch :-)
	$hash{SomeFile} = time;

	# Obtain stat information of a file
	@stat = @{$hash{SomeFile}};

	# Check if entry exists
	if(exists $hash{SomeFile}) {
		...
	}

	# Delete an entry
	delete $hash{SomeFile};


=head1 DESCRIPTION

This module provides a method of reading directories using a hash.

The keys of the hash are the directory entries and the values are a
reference to an array which holds the result of C<stat> being called
on the entry.

The access and modification times of an entry can be changed by assigning
to an element of the hash. If a single number is assigned then the access
and modification times will both be set to the same value, alternatively
the access and modification times may be set separetly by passing a 
reference to an array with 2 entries, the first being the access time
and the second being the modification time.

=over

=item new [hashref,] dirname

This method ties the hash referenced by C<hashref> to the directory C<dirname>.
If C<hashref> is omitted then C<new> returns a reference to a hash which
hash been tied, otherwise it returns the result of C<tie>

=back

=head1 AUTHOR

Graham Barr <bodg@tiuk.ti.com>, from a quick hack posted by 
Kenneth Albanowski <kjahds@kjahds.com>  to the perl5-porters mailing list

=cut

use Symbol;
use Carp;
use Tie::Hash;
use strict;
use vars qw(@ISA $VERSION);

@ISA = qw(Tie::Hash);
$VERSION = "1.00";

sub new {
    my $pkg = shift;
    my $h;

    if(@_ && ref($_[0]) {
	$h = shift;
	return tie %$h, $pkg, @_;
    }

    $h = {};
    tie %$h, $pkg, @_;
    return $h;
}

sub TIEHASH {
    my($class,$dir) = @_;
    bless [$dir,undef], $class;
}

sub FIRSTKEY {
    my($this) = @_;
    if($this->[1]) {
	rewinddir($this->[1]);
    }
    else {
	$this->[1] =  gensym();
	opendir($this->[1],$this->[0]) ||
		croak "Can't read ".$this->[0].": $!";
    }
    readdir($this->[1]);
}

sub NEXTKEY {
    my($this,$last) = @_;
    readdir($this->[1]);
}

sub EXISTS {
    my($this,$key) = @_;
    -e $this->[0] . "/" . $key;
}

sub DESTROY {
    my($this) = @_;
    closedir($this->[1])
	if($this->[1]);
}

sub FETCH {
    my($this,$key) = @_;
    [stat($this->[0] . "/" . $key)];
}

sub STORE {
    my($this,$key,$data) = @_;
    my($atime,$mtime) = ref($data) ? @$data : ($data,$data);
    utime($atime,$mtime, $this->[0] . "/" . $key);
}

sub DELETE {
    my($this,$key) = @_;
    unlink($this->[0] . "/" . $key);
}

1;

