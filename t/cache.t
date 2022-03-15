#!perl

use strict;
use warnings;

use Template::Plugin::Cache;

use Template::Test;
use Template qw( :status );

$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;

test_expect(\*DATA, {
    INTERPOLATE => 1,
    POST_CHOMP  => 1,
    PLUGIN_BASE => 'Template::Plugin',
});


exit 0;


__DATA__
[% USE memoize = Memoize %]
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% memoize.process( 'cache_me', expires_in => 15 ) %]
[% change_me %]
-- expect --
Hello
after
-- test --
[% USE memoize = Memoize %]
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% memoize.inc( 'cache_me', expires_in => 15 ) %]
[% change_me %]
-- expect --
Hello
before
-- test --
[% USE memoize = Memoize %]
[% BLOCK cache_me %]
 Hello [% name %]
[% END %]
[% SET name = 'Suzanne' %]
[% memoize.process( 'cache_me', keys => { 'name' => name } ) %]
[% SET name = 'World' %]

[% memoize.process( 'cache_me', keys => { 'name' => name } ) %]
-- expect --
 Hello Suzanne
 Hello World
