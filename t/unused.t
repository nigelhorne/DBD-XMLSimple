#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('DBD:XMLSimple');
new_ok('DBD:XMLSimple');
plan(tests => 2);
