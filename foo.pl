#!/usr/bin/perl

use warnings;
use strict;
use 5.010;
use experimental 'signatures';

use blib;
use Template::Context;
use Template::Plugin::Memoize;

#use CHI;


#my         $cache = CHI->new(
#    driver         => 'File',
#    root_dir       => '/tmp/scratch',
#    depth => 2,
#);
#
#my $key = 'stash5';
#$cache->set( $key, 'Stashed in 5', 90 );
#my $stuff = $cache->get( $key );
#say "[$stuff] is back";
#
my $context = Template::Context->new();
my $cache = Template::Plugin::Memoize->new( $context, {} );


#{use Data::Dumper; local $Data::Dumper::Sortkeys=1; warn Dumper( $cache)}
#my $x = $context->include( 'blah.ttml' );
#{use Data::Dumper; local $Data::Dumper::Sortkeys=1; warn Dumper( $x )}

#my $x = $cache->process( 'blah.ttml' );
my $x = $context->process( 'blah.ttml' );
say "[$x]"

#  [% cache.inc(
#	       'template' => 'slow.html',
#	       'keys' => {'user.name' => user.name},
#	       'ttl' => 360
#	       ) %]
