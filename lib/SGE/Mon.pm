package SGE::Mon;
use Dancer2;
use Data::Dumper;
use Dancer2::Plugin::Ajax;
use Dancer2::Plugin::Cache::CHI;
use XML::Simple qw( :strict );

#set serializer => 'JSON';

set layout => 'main';

my $xs = XML::Simple->new();

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/nodes' => sub {
		my $stash = get_qstat_all();
		template nodes => $stash, { layout => 'monitor' };
};

get '/jobs_running' => sub {
		my $stash = get_qstat_all();
		template jobs_running => $stash, { layout => 'monitor' };
};

get '/jobs_pending' => sub {
		my $stash = get_qstat_all();
		template jobs_pending => $stash, { layout => 'monitor' };
};

sub get_qstat_all {
		my $qstat_all = cache_get 'qstat_all';
		if ( !$qstat_all ) {
			$qstat_all = process_qstat_all();
			cache_set 'qstat_all', $qstat_all;
		}
		return $qstat_all;
}

sub process_qstat_all {

    my $qstat_xml    = `qstat -u '*' -f -xml`;
    my $qstat_ref    = $xs->XMLin( $qstat_xml, KeyAttr => {}, ForceArray => [] );
    my $qstat_queues = $qstat_ref->{'queue_info'}->{'Queue-List'};
    my $qstat_jobs   = $qstat_ref->{'job_info'}->{'job_list'};

    my @nodes;
    my @jobs_running;
    for my $queue (@$qstat_queues) {
        for my $job ( @{ $queue->{'job_list'} } ) {
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

		return
      {
        qstat        => $qstat_ref,
        nodes        => \@nodes,
        jobs_running => \@jobs_running,
        jobs_pending => \@jobs_pending,
      };
};

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

hook before_template_render => sub {
	my $tokens = shift;
	$tokens->{config} = config;
};


true;
