package Template::Plugin::Memoize;

use warnings;
use strict;
use parent 'Template::Plugin';

=head1 NAME

Template::Plugin::Memoize - Memoize/cache output of templates

=head1 VERSION

v1.0.0

=cut

our $VERSION = 'v1.0.0';

=head1 SYNOPSIS

    [% USE memoize = Memoize %]

    [% memoize.inc(
        'template' => 'slow.html',
        'keys' => {'user.name' => user.name},
        'ttl' => 360
        )
    %]

    # or with a pre-defined Cache::* object and key
    [% USE memoize = Memoize( cache => mycache ) %]
    [% memoize.inc(
           'template' => 'slow.html',
           'key'      => mykey,
           'ttl'      => 360
           )
    %]


=head1 DESCRIPTION

The Memoize plugin allows you to cache generated output from a template.
You load the plugin with the standard syntax:

    [% USE memoize = Memoize %]

This creates a plugin object with the name C<memoize>.  You may also
specify parameters for the default Cache module (Cache::FileCache),
which is used for storage.

    [% USE mycache = Cache(namespace => 'MyCache') %]

Or use your own Cache object:

    [% USE mycache = Cache(cache => mycacheobj) %]

The only methods currently available are include and process,
abbreviated to "inc" and "proc" to avoid clashing with built-in
directives.  They work the same as the standard INCLUDE and PROCESS
directives except that they will first look for cached output from the
template being requested and if they find it they will use that
instead of actually running the template.

  [% cache.inc(
        'template' => 'slow.html',
        'keys' => {'user.name' => user.name},
        'ttl' => 360
        ) %]

The template parameter names the file or block to include.  The keys
are variables used to identify the correct cache file.  Different
values for the specified keys will result in different cache files.
The ttl parameter specifies the "time to live" for this cache file, in
seconds.

Why the ugliness on the keys?  Well, the TT dot notation can only be
resolved correctly by the TT parser at compile time.  It's easy to
look up simple variable names in the stash, but compound names like
"user.name" are hard to resolve at runtime.  I may attempt to fake
this in a future version, but it would be hacky and might cause
problems.

You may also use your own key value:

  [% cache.inc(
        'template' => 'slow.html',
        'key'      => yourkey,
        'ttl'      => 360
        ) %]

=cut

sub new {
    my ( $class, $context, $params ) = @_;
    my $cache;
    if ( $params->{cache} ) {
        $cache = delete $params->{cache};
    }
    else {
        require Cache::FileCache;
        $cache = Cache::FileCache->new($params);
    }
    my $self = bless {
        CACHE   => $cache,
        CONFIG  => $params,
        CONTEXT => $context,
    }, $class;
    return $self;
}

#------------------------------------------------------------------------
# $cache->include({
#                 template => 'foo.html',
#                 keys     => {'user.name', user.name},
#                 ttl      => 60, #seconds
#                });
#------------------------------------------------------------------------

sub inc {
    my ( $self, $params ) = @_;
    $self->_cached_action( 'include', $params );
}

sub proc {
    my ( $self, $params ) = @_;
    $self->_cached_action( 'process', $params );
}

sub _cached_action {
    my ( $self, $action, $params ) = @_;
    my $key;
    if ( $params->{key} ) {
        $key = delete $params->{key};
    }
    else {
        my $cache_keys = $params->{keys};
        $key = join(
            ':',
            (
                $params->{template},
                map { "$_=$cache_keys->{$_}" } sort keys %{$cache_keys}
            )
        );
    }
    my $result = $self->{CACHE}->get($key);
    if ( !$result ) {
        $result = $self->{CONTEXT}->$action( $params->{template} );
        $self->{CACHE}->set( $key, $result, $params->{ttl} );
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
