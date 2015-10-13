package SGE::Mon;
use Dancer2;
use Dancer2::Plugin::Ajax;
use Dancer2::Plugin::Cache::CHI;
use XML::Simple qw( :strict );

# default template to use for pages
set layout => 'main';

my $xs = XML::Simple->new();

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
    my $qstat_data = get_qstat_all();
    for my $key ( keys %$qstat_data ) {
        $tokens->{$key} = $qstat_data->{ $key };
    }
    $tokens->{config} = config;
};

# get qstat data from cache
sub get_qstat_all {
    my $cache_key = 'qstat_all';

    my $qstat_all = cache_get $cache_key;
    if ( !$qstat_all ) {
        info "Failed to find cache key '$cache_key' in stash, creating data now...";
        $qstat_all = process_qstat_all();
        info "Storing qstat data in cache '$cache_key'";
        cache_set $cache_key, $qstat_all;
    }
    else {
        info "Retrieved qstat data from cache";
    }
    return $qstat_all;
}

# parse information from qstat (XML)
sub process_qstat_all {

    my $qstat_xml = `qstat -u '*' -f -xml`;
    my $qstat_ref = $xs->XMLin( $qstat_xml, KeyAttr => {}, ForceArray => [ qr/list$/i ] );
    my $qstat_queues = $qstat_ref->{'queue_info'}->{'Queue-List'} || [];
    my $qstat_jobs   = $qstat_ref->{'job_info'}->{'job_list'} || [];

    my @nodes;
    my @jobs_running;
    for my $queue (@$qstat_queues) {
		    my $job_list = $queue->{'job_list'} || [];

        for my $job ( @$job_list ) {
            push @jobs_running,
              {
                owner      => $job->{JB_owner},
                start_time => $job->{JAT_start_time},
                job_number => $job->{JB_job_number},
                slots      => $job->{slots},
                name       => $job->{JB_name},
                priority   => $job->{JAT_prio},
                state      => $job->{state},
              };
        }
        push @nodes,
          {
            name        => $queue->{name},
            arch        => $queue->{arch},
            slots_used  => $queue->{slots_used},
            slots_resv  => $queue->{slots_resv},
            slots_total => $queue->{slots_total},
            qtype       => $queue->{qtype},
            state       => $queue->{state},
          };
    }

    my @jobs_pending;
    for my $job (@$qstat_jobs) {
        push @jobs_pending,
          {
            queue_name      => $job->{queue_name},
            owner           => $job->{JB_owner},
            job_number      => $job->{JB_job_number},
            state           => $job->{state},
            name            => $job->{JB_name},
            slots           => $job->{slots},
            priority        => $job->{JAT_prio},
            submission_time => $job->{JB_submission_time},
          };
    }

    return {
        qstat        => $qstat_ref,
        nodes        => \@nodes,
        jobs_running => \@jobs_running,
        jobs_pending => \@jobs_pending,
    };
}

# return JSON data structure to describe job detail
ajax '/job/:job_id' => sub {
    my $job_id = params->{job_id};

    $job_id =~ /^([0-9]+)$/
      or die "! Error: expected an integer as job_id (got '$job_id')";

    my $job_id_clean = $1;

    my $qstat_xml = `qstat -j $job_id_clean -xml`;

    my $qstat_ref = $xs->XMLin( $qstat_xml, KeyAttr => {}, ForceArray => [] );

    my $qstat_job_fields = $qstat_ref->{'djob_info'}->{'element'};

    my %job_data;
    for my $qstat_key ( keys %{$qstat_job_fields} ) {
        my $job_value = $qstat_job_fields->{$qstat_key};
        ( my $job_key = $qstat_key ) =~ s/^JB_//;
        $job_data{$job_key} = $job_value unless ref $job_value;
    }

    to_json( \%job_data );
};

true;
