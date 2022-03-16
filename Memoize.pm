package Template::Plugin::Memoize;

=head1 NAME

Template::Plugin::Memoize - Memoize/cache output of templates

=head1 VERSION

v1.0.0

=cut

our $VERSION = 'v1.0.0';

=head1 SYNOPSIS

    [% USE memoize = Memoize %]
    # or with a pre-defined Cache::* object and key
    [% USE memoize = Memoize( cache => mycache ) %]

    [% memoize.include( 'slow.html',
        {
            keys       => { userid => user.userid },
            expires_in => '10 m',
        )
    %]

=head1 DESCRIPTION

The Memoize plugin allows you to cache generated output from a template.
You load the plugin with the standard syntax:

    [% USE memoize = Memoize %]

This creates a plugin object with the name C<memoize>.  You may also
specify parameters for the CHI module (L<https://metacpan.org/pod/CHI>)
which is used for storage.

    [% USE mycache = Cache(
        {
            driver     => 'File',
            root_dir   => '/tmp/scratch',
            expires_in => '10 minutes',
        }
    %]

Or use your own Cache object:

    [% USE mycache = Cache(cache => mycacheobj) %]

The methods available are C<include>, C<process> and C<insert>,
corresponding to the C<INCLUDE>, C<PROCESS> and C<INSERT> directives.
They work the same as the standard INCLUDE and PROCESS directives except
that they will first look for cached output from the template being
requested and if they find it they will use that instead of actually
running the template.

    [% cache.include(
        'slow.html',
        {
            keys => { useid => user.userid },
            expires_in => 3600, # could also have been "1 hour"
        )
    ) %]

The first parameter names the file or block to include.  The keys
are variables used to identify the correct cache file.  Different
values for the specified keys will result in different cache files.

Why the ugliness on the keys?  Well, the TT dot notation can only be
resolved correctly by the TT parser at compile time.  It's easy to
look up simple variable names in the stash, but compound names like
"user.name" are hard to resolve at runtime.

You may also use your own key value:

    [% cache.include(
        'slow.html',
        {
            key => 'somekeyvalue',
        }
    ) %]

=cut

use warnings;
use strict;
use parent 'Template::Plugin';

use CHI;

sub new {
    my $class   = shift;
    my $context = shift;
    my $params  = shift // {};

    my $cache;
    if ( $params->{cache} ) {
        $cache = delete $params->{cache};
    }
    else {
        my $cache_params = delete $params->{cache_params};
        # If no cache parameters sent, supply some defaults.
        if ( !$cache_params ) {
            $cache_params = {
                driver             => 'File',
                root_dir           => '/tmp/cache',
                default_expires_in => 600, # 10 minutes
            };
        }
        # XXX Can the CHI constructor fail?
        $cache = CHI->new( %{$cache_params} );
    }
    $cache->clear();
    my $self = bless {
        CACHE   => $cache,
        CONFIG  => $params,
        CONTEXT => $context,
    }, $class;

    return $self;
}

sub include {
    my $self = shift;
    $self->_cached_action( 'include', @_ );
}

sub process {
    my $self = shift;
    {use Data::Dumper; local $Data::Dumper::Sortkeys=1; warn Dumper( INSIDE_PROCESS => \@_ )}
    $self->_cached_action( 'process', @_ );
}

sub insert {
    my $self = shift;
    $self->_cached_action( 'insert', @_ );
}

sub _cached_action {
    my ( $self, $action, $template, $params ) = @_;

    my $key;
    if ( defined $params->{key} ) {
        $key = delete $params->{key};
    }
    elsif ( defined( my $cache_keys = $params->{keys} ) ) {
        $key = join(
            ':',
            (
                $template,
                map { "$_=" . ($cache_keys->{$_}//'') } sort keys %{$cache_keys}
            )
        );
    }
    else {
        $key = $template;
    }
    my $result = $self->{CACHE}->get($key);
    if ( !defined($result) ) {
        $result = $self->{CONTEXT}->$action( $template );
        $self->{CACHE}->set( $key, $result ); # XXX Allow other args to set?
    }
    return $result;
}


=head1 QUESTIONS

=head2 How is this different from the caching already built into Template Toolkit?

That cache is for caching the template files and the compiled version
of the templates.  This cache is for caching the actual output from
running a template.

=head2 How is this different from Template::Plugin::Cache?

This is based on Template::Plugin::Cache, but is different enough I felt
that it made sense to give it a new name.

=head2 Who would benefit from memoizing templates?

There are two situations where this might be useful.  The first is if you
are using a plugin or object inside your template that does something
slow, like accessing a database or a disk drive or another process.
The DBI plugin, for example.  I don't build my apps this way (I use a
pipeline model with all the data collected before the template is run),
but I know some people do.

The other situation is if you have an unusually complex template that
takes a significant amount of time to run.  Template Toolkit is quite
fast, so it's uncommon for the actual template processing to take any
noticeable amount of time, but it is possible in extreme cases.

=head2 Any "gotchas" I should know about?

If you have a template that produces side effects when run, like modifying
a database or object, these side effects will not be captured and caching
will break them. The cache only caches actual template output.

=head1 AUTHORS

Andy Lester (andy@petdance.com) wrote this, using Perrin Harkins'
Template::Plugin::Cache as a starting point.

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/petdance/template-plugin-memoize/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Memoize

You can also look for information at:

=over 4

=item * Template::Plugin::Memoize's bug queue

L<http://github.com/petdance/template-plugin-memoize/issues>

=item * Source code repository

L<http://github.com/petdance/template-plugin-memoize/tree/master>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Perrin Harkins for the original Template::Plugin::Cache.

=head1 COPYRIGHT & LICENSE

Copyright 2022 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut

1; # End of Template::Plugin::Memoize
