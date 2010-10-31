use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'kanopya',
    AUTHOR              => q{"Hedera Development Team" <"dev@hederatech.com">},
    VERSION_FROM        => 'VERSION',
    ABSTRACT_FROM       => 'ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'test-*' },
);
