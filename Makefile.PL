use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

WriteMakefile(
    NAME		=> 'DBD::XMLSimple',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/DBD/XMLSimple.pm',
    ABSTRACT_FROM       => 'lib/DBD/XMLSimple.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
    },
    PREREQ_PM => {
	'DBI' => 1.636,
	'DBI::DBD' => '12.015129',
	'XML::Twig' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'DBD::XMLSimple-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/DBD::XMLSimple.git',
			web => 'https://github.com/nigelhorne/DBD::XMLSimple',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
