package DBD::XMLSimple;

=head1 NAME

DBD::XMLSimple - Access XML data via the DBI interface

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

=cut

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

our $VERSION = '0.01';
our $drh = undef;

sub driver
{
	return $drh if $drh;

	my($class, $attr) = @_;

	# $drh = DBI::_new_drh("$class::dr", {
	$drh = $class->SUPER::driver({
		'Name' => 'XML',
		'Version' => $VERSION,
		'Attribution' => 'DBD::XMLSimple by Nigel Horne',
	});

	if($drh) {
		unless($methods_already_installed++) {
			DBI->setup_driver(__PACKAGE__);
			DBD::XMLSimple::db->install_method('ad_import');
		}
	}

	return $drh;
}

sub CLONE
{
	undef $drh;
}

package DBD::XMLSimple::dr;

use vars qw($imp_data_size);

sub disconnect_all
{
	shift->{tables} = {};
}

sub DESTROY
{
	shift->{tables} = {};
}

package DBD::XMLSimple::db;

use vars qw($imp_data_size);

require Cwd;
require File::Spec;

$DBD::XMLSimple::db::imp_data_size = 0;
@DBD::XMLSimple::db::ISA = qw(DBI::DBD::SqlEngine::db);

sub ad_import
{
	my $dbh = shift;
	my($table_name, $format, $file_name, $flags) = @_;

	die if($format ne 'XML');

	$dbh->{filename} = $file_name;
}

package DBD::XMLSimple::st;

use strict;
use warnings;

use vars qw($imp_data_size);

$DBD::XMLSimple::st::imp_data_size = 0;
@DBD::XMLSimple::st::ISA = qw(DBI::DBD::SqlEngine::st);

package DBD::XMLSimple::Statement;

use strict;
use warnings;
use XML::Twig;

@DBD::XMLSimple::Statement::ISA = qw(DBI::DBD::SqlEngine::Statement);

sub open_table($$$$$)
{
	my($self, $data, $tname, $createMode, $lockMode) = @_;
	my $dbh = $data->{Database};

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
		foreach my $leaf($record->children) {
			$row{$leaf->name()} = $leaf->field();
			$col_names{$leaf->name()} = 1;
		}
		$table{data}->{$record->att('id')} = \%row;
		$rows++;
	}
	use Data::Dumper;
	my $d = Data::Dumper->new([\%table]);

	$data->{'rows'} = $rows;

	$table{'table_name'} = $tname;
	my @col_names = sort keys %col_names;
	$table{'col_names'} = \@col_names;

	return DBD::XMLSimple::Table->new($data, \%table);
}

package DBD::XMLSimple::Table;

use strict;
use warnings;

@DBD::XMLSimple::Table::ISA = qw(DBI::DBD::SqlEngine::Table);

sub new
{
	my($class, $data, $attr, $flags) = @_;

	$attr->{table} = $data;
	$attr->{readonly} = 1;
	$attr->{cursor} = 0;

	my $rc = $class->SUPER::new($data, $attr, $flags);

	$rc->{col_names} = $attr->{col_names};
	return $rc;
}

sub fetch_row($$)
{
	my($self, $data) = @_;
	my $requested_cols = $data->{sql_stmt}->{NAME};
	my $dbh = $data->{Database};

	if($self->{cursor} >= $data->{rows}) {
		return;
	}
	$self->{cursor}++;

	my @fields;
	foreach my $col(@{$self->{'col_names'}}) {
		push @fields, $self->{'data'}->{$self->{'cursor'}}->{$col};
	}
	$self->{row} = \@fields;

	return $self->{row};
}

sub seek($$$$)
{
	my($self, $data, $pos, $whence) = @_;

	print "seek $pos $whence, not yet implemented\n";
}

sub complete_table_name($$$$)
{
	my($self, $meta, $file, $respect_case, $file_is_table) = @_;
}

sub open_data
{
	my($className, $meta, $attrs, $flags) = @_;
}

sub bootstrap_table_meta
{
	my($class, $dbh, $meta, $table, @other) = @_;

	$class->SUPER::bootstrap_table_meta($dbh, $meta, $table, @other);

	$meta->{filename} ||= $dbh->{filename};
	$meta->{table} = $table;

	$meta->{sql_data_source} ||= __PACKAGE__;
}

sub get_table_meta($$$$;$)
{
	my($class, $dbh, $table, $file_is_table, $respect_case) = @_;

	my $meta = $class->SUPER::get_table_meta($dbh, $table, $respect_case, $file_is_table);
	$table = $meta->{table};

	return unless $table;

	return($table, $meta);
}

1;
