#!perl -wT

use strict;
use warnings;
use Test::Most;
# use Test::NoWarnings;	# FIXME: remove once registration completed

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('DBI');
}

if($ENV{'TRAVIS_TESTING'}) {
	plan skip_all => 'FIXME: this test fails on Travis';
} else {
	diag("Ignore warnings about unregistered driver and drv_prefix for now");

	my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

	$dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');
	$dbh->func('person2', 'XML', [<DATA>], 'x_import');

	my $sth = $dbh->prepare("Select email FROM person2 WHERE name = 'Nigel Horne'");
	$sth->execute();
	my @rc = @{$sth->fetchall_arrayref()};
	ok(scalar(@rc) == 1);
	my @row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok($row1[0] eq 'njh@bandsman.co.uk');
}
done_testing(4);

__DATA__
<?xml version="1.0" encoding="US-ASCII"?>
<table>
	<row id="1">
		<name>Nigel Horne</name>
		<email>njh@bandsman.co.uk</email>
	</row>
	<row id="2">
		<name>A N Other</name>
		<email>somebody@example.com</email>
	</row>
</table>
