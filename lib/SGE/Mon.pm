package SGE::Mon;
use Dancer2;
use Dancer2::Plugin::Ajax;
use Dancer2::Plugin::Cache::CHI;
use Dancer2::Plugin::DirectoryView;
use SGE::Mon::Util;

# default template to use for pages
set layout => 'main';

our $VERSION = '0.1';

# routes: define how we will respond to particular URLs
get '/' => sub {
    template 'index';
};

get '/nodes' => sub {
    template 'nodes', {}, { layout => 'monitor' };
};

get '/jobs_running' => sub {
    template 'jobs_running', {}, { layout => 'monitor' };
};

get '/jobs_pending' => sub {
    template 'jobs_pending', {}, { layout => 'monitor' };
};

# add qstat and config to stash for all template pages
hook before_template_render => sub {
    my $tokens = shift;
		my $nocache = param "nocache" || 0;
		my $qstat_data = get_qstat_all( nocache => $nocache );

    for my $key ( keys %$qstat_data ) {
        $tokens->{$key} = $qstat_data->{ $key };
    }
    $tokens->{config} = config;
};

# return JSON data structure to describe job detail
ajax '/job/:job_id' => sub {
    my $job_id = params->{job_id};

    $job_id =~ /^([0-9]+)$/
      or die "! Error: expected an integer as job_id (got '$job_id')";

    my $job_id_clean = $1;

    my $job_data = SGE::Mon::Util::parse_qstat_job( $job_id_clean );

    to_json( $job_data );
};


# get qstat data from cache
sub get_qstat_all {
		my %params = @_;
		my $nocache = defined $params{nocache} ? $params{nocache} : 0;
    my $cache_key = 'qstat_all';

    my $qstat_all = cache_get $cache_key;

    if ( !$qstat_all || $nocache ) {
				if ( !$qstat_all ) {
        	info "Failed to find cache key '$cache_key' in stash, creating data now...";
        }
				else {
					info "Requested cache refresh";
				}
				$qstat_all = SGE::Mon::Util::parse_qstat_all();
        info "Storing qstat data in cache '$cache_key'";
        cache_set $cache_key, $qstat_all;
    }
    else {
        info "Retrieved qstat data from cache";
    }
    return $qstat_all;
}

true;
