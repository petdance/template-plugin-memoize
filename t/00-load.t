#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Template::Plugin::Memoize;

diag( "Testing Template::Plugin::Memoize $Template::Plugin::Memoize::VERSION, Perl $], $^X" );

pass( 'All modules loaded OK.' );

exit 0;
