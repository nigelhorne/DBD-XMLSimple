#!perl -wT

use strict;
use warnings;
use Test::Most;
# use Test::NoWarnings;	# FIXME: remove once registration completed

eval 'use autodie qw(:all)';	# Test for open/close failures
use FindBin qw($Bin);

if($ENV{'TRAVIS_PERL_VERSION'}) {
	plan skip_all => 'FIXME: this test fails on Travis';
} else {
	plan tests => 4;
	use_ok('DBI');
	diag("Ignore warnings about unregistered driver and drv_prefix for now");

	my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

	$dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');
	$dbh->func('person', 'XML', "$Bin/../data/person.xml", 'x_import');

	my $sth = $dbh->prepare("Select name FROM person WHERE email = 'nobody\@example.com'");
	$sth->execute();
	my @rc = @{$sth->fetchall_arrayref()};
	ok(scalar(@rc) == 1);
	my @row1 = @{$rc[0]};
	ok(scalar(@row1) == 1);
	ok($row1[0] eq 'A N Other');
}
