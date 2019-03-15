package SGE::Mon::Util;

use strict;
use warnings;
use Carp qw/ croak /;

use XML::Simple qw( :strict );
use namespace::autoclean;

my $xs = XML::Simple->new();

# parse information from qstat (XML)
sub parse_qstat_all {

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
        timestamp    => "" . localtime,
        qstat        => $qstat_ref,
        nodes        => \@nodes,
        jobs_running => \@jobs_running,
        jobs_pending => \@jobs_pending,
    };
}

sub parse_qstat_job {
  my $job_id = shift;

  $job_id =~ m/^[0-9a-zA-Z]+$/
    or croak "! Error: string '$job_id' does not look like a valid job ID";

  my $qstat_xml = `qstat -j $job_id -xml`;

  my $qstat_ref = $xs->XMLin( $qstat_xml, KeyAttr => {}, ForceArray => [] );

  my $qstat_job_fields = $qstat_ref->{'djob_info'}->{'element'};

  my %job_data;
  for my $qstat_key ( keys %{$qstat_job_fields} ) {
      my $job_value = $qstat_job_fields->{$qstat_key};
      ( my $job_key = $qstat_key ) =~ s/^JB_//;
      $job_data{$job_key} = $job_value unless ref $job_value;
  }

  return \%job_data;
}


1;
