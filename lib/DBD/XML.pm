package DBD::XML;

# GPL2.  Don't use this yet, it's a WIP
# Change ad_import to xml_import once it's been registered
# Re-uses code from existing DBD Drives, especially DBD::AnyData
# Nigel Horne: njh@bandsman.co.uk

require DBI::DBD::SqlEngine;
use base qw(DBI::DBD::SqlEngine);
# require SQL::Statement;
# require SQL::Eval;
use Data::Dumper;

use vars qw($VERSION $drh $methods_already_installed);

$VERSION = '0.01';
our $drh = undef;

sub driver
{
	return $drh if $drh;

	my ($class, $attr) = @_;

	# $drh = DBI::_new_drh("$class::dr", {
	$drh = $class->SUPER::driver({
		'Name' => 'XML',
		'Version' => $VERSION,
		'Attribution' => 'DBD::XML by Nigel Horne',
	});

	if($drh) {
		unless($methods_already_installed++) {
			DBI->setup_driver(__PACKAGE__);
			DBD::XML::db->install_method('ad_import');
		}
	}

	return $drh;
}

sub CLONE
{
	undef $drh;
}

package DBD::XML::dr;

use vars qw($imp_data_size);

sub disconnect_all
{
# print "disconnect_all\n";
	shift->{tables} = {};
}

sub DESTROY
{
# print "DESTROY\n";
	shift->{tables} = {};
}

package DBD::XML::db;

use vars qw($imp_data_size);

require Cwd;
require File::Spec;

$DBD::XML::db::imp_data_size = 0;
@DBD::XML::db::ISA = qw(DBI::DBD::SqlEngine::db);

sub ad_import
{
	my $dbh = shift;
	my($table_name, $format, $file_name, $flags) = @_;

	die if($format ne 'XML');

# print ">>>>>>ad_import\n";

	if(ref($file_name)) {
	}
# print ">>>>>>>>$file_name\n";
	$dbh->{filename} = $file_name;
}

package DBD::XML::st;

use strict;
use warnings;

use vars qw($imp_data_size);

$DBD::XML::st::imp_data_size = 0;
@DBD::XML::st::ISA = qw(DBI::DBD::SqlEngine::st);

package DBD::XML::Statement;

use strict;
use warnings;
use XML::Twig;

@DBD::XML::Statement::ISA = qw(DBI::DBD::SqlEngine::Statement);

sub open_table ($$$$$)
{
	my ($self, $data, $tname, $createMode, $lockMode) = @_;
	my $dbh = $data->{Database};

# print "open_table: ", $dbh->{filename}, "\n";
# print ">>>>>>>>>>$data, $tname\n";

	my $twig = XML::Twig->new();
	my $source = $dbh->{filename};
	if(ref($source) eq 'ARRAY') {
		$twig->parse(join('', @{$source}));
	} else {
		$twig->parsefile($source);
	}

	my $root = $twig->root;
	my %table;
	my $rows;
	my %col_names;
	foreach my $record($root->children()) {
		my %row;
# print "child\n";
# print $record->name(), ': ', $record->field(), "\n";
# print "id is: ", $record->att('id'), "\n";
# $record->print();
		foreach my $leaf($record->children) {
# print "gchild\n";
# $leaf->print();
# print $leaf->name(), ': ', $leaf->field(), "\n";
			$row{$leaf->name()} = $leaf->field();
			$col_names{$leaf->name()} = 1;
		}
		$table{$record->att('id')} = \%row;
		$rows++;
	}
	use Data::Dumper;
	my $d = Data::Dumper->new([\%table]);
# print "open_table has read:\n", $d->Dump();

	$data->{'rows'} = $rows;

	$table{'table_name'} = $tname;
	my @col_names = sort keys %col_names;
# print ">>>>>>>>", @col_names, "\n";
	$table{'col_names'} = \@col_names;

	return DBD::XML::Table->new($data, \%table);
}

package DBD::XML::Table;

use strict;
use warnings;

use Params::Util qw(_HASH0);

@DBD::XML::Table::ISA = qw(DBI::DBD::SqlEngine::Table);

sub new
{
	my ($proto, $data, $attr, $flags) = @_;

# print "D:X:T:new $attr\n";
	# my @col_names = keys %{$attr};
	# my @col_names = ('name', 'email');
	# $attr->{col_names} = \@col_names;
# print ">>>>>>>>", @{$attr->{col_names}}, "\n";
	$attr->{table} = $data;
	$attr->{readonly} = 1;
	$attr->{cursor} = 0;
# use Data::Dumper;
# my $d = Data::Dumper->new([$attr]);
# print "attr: ", $d->Dump();
# $d = Data::Dumper->new([$data]);
# print "data: ", $d->Dump();
	return $proto->SUPER::new($data, $attr, $flags);
}

sub fetch_row ($$)
{
	my ($self, $data) = @_;
# print "fetch_row\n";
	my $requested_cols = $data->{sql_stmt}->{NAME};
# print "requested_cols: ", join(' ', @{$requested_cols}), "\n";
	my $dbh = $data->{Database};
# print " compare ", $self->{cursor}, '>=', $data->{rows}, "\n";
	if($self->{cursor} >= $data->{rows}) {
		return;
	}
	$self->{cursor}++;
# use Data::Dumper;
# my $d = Data::Dumper->new([$data]);
# print "data: ", $d->Dump();
# print "njh back: ", $data->{njh}, "\n";
# $d = Data::Dumper->new([$self]);
# print "self: ", $d->Dump();
# $d = Data::Dumper->new([$data->{sql_stmt}]);
# print "stmt: ", $d->Dump(), "\n";
	# my @fields;
	# foreach my $col(@{$requested_cols}) {
		# push @fields, $self->{$self->{'cursor'}}->{$col};
	# }
	# my @fields = values %{$self->{$self->{'cursor'}}};
	my @fields;
	foreach my $col(sort keys %{$self->{'1'}}) {
		push @fields, $self->{$self->{'cursor'}}->{$col};
	}
# my $d = Data::Dumper->new([\@fields]);
# print "return: ", $d->Dump(), "\n";
	$self->{row} = \@fields;
	return $self->{row};
}

sub seek ($$$$)
{
	my ($self, $data, $pos, $whence) = @_;

	print "seek $pos $whence, not yet implemented\n";
}

sub complete_table_name($$$$)
{
	my ($self, $meta, $file, $respect_case, $file_is_table) = @_;

# print "complete_table_name $file $file_is_table\n";
}

sub open_data
{
	my ($className, $meta, $attrs, $flags) = @_;
}

sub bootstrap_table_meta
{
	my ($self, $dbh, $meta, $table, @other) = @_;

	$self->SUPER::bootstrap_table_meta ($dbh, $meta, $table, @other);
# print "bootstrap_table_meta $table\n";

	exists $meta->{filename} or $meta->{filename} = $dbh->{filename};
# use Data::Dumper;
my $d = Data::Dumper->new([$meta]);
# print "meta: ", $d->Dump();
# my $d = Data::Dumper->new([$table]);
# print "table: ", $d->Dump();
# $d = Data::Dumper->new([$dbh]);
# print "dbh: ", $d->Dump();
	$meta->{table} = 'something must go here - what though?';
	my @col_names = ('email', 'name');	# FIXME
	$meta->{col_names} = \@col_names;

	defined ($meta->{sql_data_source}) or
		$meta->{sql_data_source} = __PACKAGE__;
}

sub get_table_meta ($$$$;$)
{
	my ($self, $dbh, $table, $file_is_table, $respect_case) = @_;

	my $meta = $self->SUPER::get_table_meta ($dbh, $table, $respect_case, $file_is_table);
	$table = $meta->{table};
	use Data::Dumper;
	my $d = Data::Dumper->new([$meta]);
# print "meta: ", $d->Dump();
# print "get_meta_table $table $meta\n";
	return unless $table;

	return ($table, $meta);
}

1;
