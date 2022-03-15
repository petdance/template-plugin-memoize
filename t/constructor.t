#!perl

use strict;
use warnings;

use Template;
use Template::Plugin::Memoize;


my $context = Template->new();
my $cache = Template::Plugin::Memoize->new( $context, {} );


#{use Data::Dumper; local $Data::Dumper::Sortkeys=1; warn Dumper( $cache)}
$cache->process( { template => 'blah.ttml' } );



exit 0;


__DATA__
[% USE cache = Cache %]
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% cache.proc(
             'template' => 'cache_me',
             'ttl' => 15
             ) %]
[% change_me %]
-- expect --
Hello
after
-- test --
