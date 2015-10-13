use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'SGE::Mon',
    AUTHOR              => q{IAN SILLITOE <i.sillitoe@ucl.ac.uk>},
    VERSION_FROM        => 'lib/SGE/Mon.pm',
    ABSTRACT            => 'Simple web-based app to monitor SGE jobs',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer2'     => 0.162000,
				'Dancer2::Plugin::Ajax' => 0,
				'Dancer2::Plugin::Cache::CHI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SGE-Mon-*' },
);
