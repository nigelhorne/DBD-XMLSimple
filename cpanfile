# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.6.2';

requires 'DBI::DBD::SqlEngine', '0.06';
requires 'Data::Reuse';
requires 'SQL::Statement', '1.410';
requires 'XML::Twig';

on 'test' => sub {
	requires 'Carp';
	requires 'File::Slurp';
	requires 'File::Temp';
	requires 'IPC::System::Simple';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Test::DatabaseRow';
	requires 'Test::DescribeMe';
	requires 'Test::Differences';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Script', '1.12';
	requires 'autodie';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
