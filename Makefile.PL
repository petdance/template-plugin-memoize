package main;

use 5.10.0;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.46;

WriteMakefile(
    NAME                => 'Template::Plugin::Memoize',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Memoize.pm',
    ABSTRACT_FROM       => 'Memoize.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic_2',
    PREREQ_PM => {
        'Test::More' => 0.88,
    },
    META_MERGE => {
        resources => {
            bugtracker  => 'http://github.com/petdance/template-plugin-memoize/issues',
            repository  => 'http://github.com/petdance/template-plugin-memoize/tree/master',
            license     => 'https://dev.perl.org/licenses/artistic.html',
        }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-Memoize-*' },
);

exit 0;

sub MY::postamble {
return <<'MAKE_FRAG';
.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.git \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

critic:
	perlcritic -profile perlcriticrc -1 -quiet Memoize.pm t/*.t

MAKE_FRAG
}

1;
