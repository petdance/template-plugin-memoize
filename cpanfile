# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile

requires 'Template'     => '2.07';
requires 'Cache::Cache' => '1.02';

on 'test' => sub {
    requires 'Test::More' => '0.88';
};

# vi:et:sw=4 ts=4 ft=perl
