package DBD::XML;

# GPL2.  Don't use this yet, it's a WIP
# Change ad_import to xml_import once it's been registered
# Re-uses code from existing DBD Drives, especially DBD::AnyData

require DBI::DBD::SqlEngine;
use base qw(DBI::DBD::SqlEngine);
# require SQL::Statement;
# require SQL::Eval;
use Data::Dumper;

use vars qw($VERSION $err $errstr $sqlstate $drh $methods_already_installed);

$VERSION = '0.01';
our $err = 0;
our $errstr = '';
our $sqlstate = '';
our $drh = undef;

sub driver
{
	my $class = shift;
	my $attr = shift;

	return $drh if $drh;

	$drh = $class->SUPER::driver({
		'Name' => 'XML',
		'Version' => $VERSION,
		'Err' => \$DBD::XML::err,
		'Errstr' => \$DBD::XML::errstr,
		'State' => \$DBD::XML::sqlstate,
		'Attribution' => 'DBD::XML by Nigel Horne',
	});

	unless ( $methods_already_installed++ ) {
		DBD::XML::db->install_method('ad_import');
	}

	return $drh;
}

sub CLONE
{
	undef $drh;
}

package DBD::XML::dr;

use vars qw($imp_data_size);

$DBD::XML::dr::imp_data_size = 0;
@DBD::XML::dr::ISA = qw(DBI::DBD::SqlEngine::dr);

sub disconnect_all
{
	warn "disconnect_all\n";
	shift->{tables} = {};
}

sub DESTROY
{
	warn "DESTROY\n";
	shift->{tables} = {};
}

package DBD::XML::db;

use vars qw($imp_data_size);

require Cwd;
require File::Spec;

$DBD::XML::db::imp_data_size = 0;
@DBD::XML::db::ISA = qw(DBI::DBD::SqlEngine::db);

sub init_default_attributes
{
	my $dbh = shift;

	$dbh->SUPER::init_default_attributes();

	$dbh->{f_dir} = Cwd::abs_path( File::Spec->curdir() );

	return $dbh;
}

sub set_versions
{
# print "set_versions\n";
	my $this = $_[0];
	$this->{ad_version} = $DBD::XML::VERSION;
	return $this->SUPER::set_versions();
}

sub disconnect
{
# print "disconnect\n";
	my $dbh = $_[0];
	$dbh->SUPER::disconnect();
	$dbh->{ad_tables} = {};
	$dbh->STORE( 'Active', 0 );
	return 1;
}
 
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

sub validate_STORE_attr
{
print "validate_STORE_attr\n";
    my ( $dbh, $attrib, $value ) = @_;

    if ( $attrib eq "f_dir" )
    {
        -d $value
          or return $dbh->set_err( $DBI::stderr, "No such directory '$value'" );
        File::Spec->file_name_is_absolute($value)
          or $value = Cwd::abs_path($value);
    }

    return $dbh->SUPER::validate_STORE_attr( $attrib, $value );
}

sub get_avail_tables
{
print "get_avail_tables\n";
    my $dbh = $_[0];

    my @tables = $dbh->SUPER::get_avail_tables();

    my $catalog = $dbh->func( '', 'ad_get_catalog' );
    if ($catalog)
    {
        for ( keys %{$catalog} )
        {
            push( @tables, [ undef, undef, $_, "TABLE", "XML" ] );
        }
    }

    return @tables;
}

sub DESTROY
{
warn "destroy\n";
    my $dbh = shift;
    $dbh->{ad_tables} = {};
    $dbh->STORE( 'Active', 0 );
}

sub ad_get_catalog
{
print "ad_get_catalog\n";
    my $self  = shift;
    my $tname = shift;
    #################################################################
    # Patch from Wes Hardaker
    #################################################################
    if ($tname)
    {
        return $self->{ad_tables}->{$tname}
          if ( $self->{ad_tables}->{$tname} );
        return $self->{ad_tables}->{__default};
    }
    #################################################################
    return $self->{ad_tables};
}

package DBD::XML::st;    # ====== STATEMENT ======

use strict;
use warnings;

use vars qw($imp_data_size);

$DBD::XML::st::imp_data_size = 0;
@DBD::XML::st::ISA           = qw(DBI::DBD::SqlEngine::st);

# sub DESTROY ($) { undef; }

# sub finish ($) {}

package DBD::XML::Statement;

use strict;
use warnings;
use XML::Twig;

@DBD::XML::Statement::ISA = qw(DBI::DBD::SqlEngine::Statement);

sub open_table ($$$$$)
{
    my ( $self, $data, $tname, $createMode, $lockMode ) = @_;
    my $dbh = $data->{Database};

print "open_table: ", $dbh->{filename}, "\n";
# print ">>>>>>>>>>$data, $tname\n";

    my $twig = XML::Twig->new();
    $twig->parsefile($dbh->{filename});

    my $root = $twig->root;
    my %table;
    my $rows;
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
	    }
	$table{$record->att('id')} = \%row;
	$rows++;
    }
	use Data::Dumper;
	my $d = Data::Dumper->new([\%table]);
# print $d->Dump();

	$data->{'rows'} = $rows;

    return DBD::XML::Table->new($data, \%table);

    if(0) {
    # use Data::Dumper;
    # my $d = Data::Dumper->new([$data]);
    # print $d->Dump();

    my $catalog = $dbh->func( $tname, 'ad_get_catalog' );
    if ( !$catalog )
    {
        $dbh->func( [ [ $tname, 'Base', '' ] ], 'ad_catalog' );
        $catalog    = $dbh->func( $tname, 'ad_get_catalog' );
        $createMode = 'o';
        $lockMode   = undef;
    }
    my $format = $catalog->{format};
    my $file   = $catalog->{file_name};
    my $ad     = $catalog->{ad}
      #################################################################
      # Patch from Wes Hardaker
      #################################################################
      #    || XML::adTable( $format, $file, $createMode, $lockMode,
      #                         $catalog );
      || XML::adTable( $format, $file, $createMode, $lockMode, $catalog, $tname );
    #print join("\n", $format,@$file,$createMode), "\n";
    #use Data::Dumper; print Dumper $catalog;
    #################################################################
    my $table = $ad->prep_dbd_table( $tname, $createMode );
    my $cols = $table->{col_names};
    if ( $cols and ref $cols ne 'ARRAY' )
    {
        #$dbh->DBI::set_err(99, "\n  $cols\n ");
        print "\n  $cols\n ";
        exit;
    }
    if (    'Base XML HTMLtable' =~ /$catalog->{format}/
         or $file =~ /http:|ftp:/
         or ref($file) eq 'ARRAY' )
    {
        $ad->seek_first_record();
        $dbh->func( $tname, 'ad', $ad, 'ad_mod_catalog' );
    }
    return DBD::XML::Table->new($table);
    }

}

package DBD::XML::Table;

use strict;
use warnings;

use Params::Util qw(_HASH0);

@DBD::XML::Table::ISA = qw(DBI::DBD::SqlEngine::Table);

sub new
{
    my ( $proto, $data, $attr, $flags ) = @_;

    print "D:X:T:new $attr\n";
    # my @col_names = keys %{$attr};
    my @col_names = ( 'name', 'email' );
    $attr->{col_names} = \@col_names;
    $attr->{table_name} = 'person';
    $attr->{table} = $data;
    $attr->{readonly} = 1;
    $attr->{cursor} = 0;
    use Data::Dumper;
    my $d = Data::Dumper->new([$attr]);
# print "data: ", $d->Dump();
    return $proto->SUPER::new($data, $attr, $flags);
}

sub trim
{
# print "trim\n";
    my $x = $_[0];
    $x =~ s/^\s+//;
    $x =~ s/\s+$//;
    return $x;
}

sub fetch_row ($$)
{
    my ( $self, $data ) = @_;
# print "fetch_row\n";
    my $requested_cols = $data->{sql_stmt}->{NAME};
    my $dbh            = $data->{Database};
print " compare ", $self->{cursor}, '>=', $data->{rows}, "\n";
    if($self->{cursor} >= $data->{rows}) {
    	return;
    }
    $self->{cursor}++;
use Data::Dumper;
my $d = Data::Dumper->new([$data]);
# print "data: ", $d->Dump();
# print "njh back: ", $data->{njh}, "\n";
$d = Data::Dumper->new([$self]);
# print "self " , @{$requested_cols}, ": ", $d->Dump();
$d = Data::Dumper->new([$data->{sql_stmt}]);
# print "stmt: ", $d->Dump(), "\n";
	my @fields;
	foreach my $col(@{$requested_cols}) {
		push @fields, $self->{$self->{'cursor'}}->{$col};
	}
    # if ( $dbh->{ChopBlanks} )
    # {
        # @$fields = map( $_ = &trim($_), @$fields );
    # }
$d = Data::Dumper->new([@fields]);
# print "return: ", $d->Dump(), "\n";
    $self->{row} = \@fields;
    return $self->{row};
}

sub push_names ($$$)
{
print "push_names\n";
    my ( $self, $data, $names ) = @_;
    #print @$names;
    $self->{ad}->push_names($names);
}

sub push_row ($$$)
{
print "push_row\n";
    my ( $self, $data, $fields ) = @_;
    my $requested_cols = [];
    my @rc             = $data->{sql_stmt}->columns();
    push @$requested_cols, $_->{column} for @rc;
    unshift @$fields, $requested_cols;
    $self->{ad}->push_row(@$fields);
    1;
}

sub seek ($$$$)
{
print "seek\n";
    my ( $self, $data, $pos, $whence ) = @_;
    $self->{ad}->seek( $pos, $whence );
}

sub drop ($$)
{
print "drop\n";
    my ( $self, $data ) = @_;
    return $self->{ad}->drop();
}

sub truncate ($$)
{
print "truncate\n";
    my ( $self, $data ) = @_;
    $self->{ad}->truncate($data);
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

    exists  $meta->{filename}        or $meta->{filename}        = $dbh->{filename};
    $meta->{table} = 'person';
    my @col_names = ( 'name', 'email' );
    $meta->{col_names} = \@col_names;

    defined ($meta->{sql_data_source}) or
	$meta->{sql_data_source} = 'DBD::XML::Table';
    } # bootstrap_table_meta

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
} # get_table_meta

sub DESTROY
{
print "DESTROY\n";
    # wierd: this is needed to close file handle ???
    my $self = shift;
    #print "CLOSING" if $self->{ad}->{storage}->{fh};
    my $fh = $self->{ad}->{storage}->{fh} or return;
    $self->{ad}->DESTROY;
    undef $self->{ad}->{storage}->{fh};
}

1;
