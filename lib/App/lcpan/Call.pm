package App::lcpan::Call;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(call_lcpan_script);

$SPEC{call_lcpan_script} = {
    v => 1.1,
    summary => '"Call" lcpan script',
    args => {
        # XXX max_index_age (default 5 days)
        argv => {
            schema => ['array*', of=>'str*'],
            default => [],
        },
    },
};
sub call_lcpan_script {
    require Perinci::CmdLine::Call;

    my %args = @_;

    state $checked;
    unless ($checked) {
        require File::Which;
        File::Which::which("lcpan")
            or die "lcpan is not available, please install it first\n";
        my $res = Perinci::CmdLine::Call::call_cli_script(
            script => 'lcpan',
            argv   => ['stats'],
        );
        die "Can't 'lcpan stats': $res->[0] - $res->[1]\n"
            unless $res->[0] == 200;
        my $stats = $res->[2];
        if ((time - $stats->{raw_last_index_time}) > 5*86400) {
            die "lcpan index is over 5 days old, please refresh it first ".
                "with 'lcpan update'\n";
        }
    }

    my $res = Perinci::CmdLine::Call::call_cli_script(
        script => 'lcpan',
        argv   => $args{'argv'},
    );
    die "Can't 'lcpan ".join(" ", @{ $args{argv} || [] })."': $res->[0] - $res->[1]\n"
        unless $res->[0] == 200;
    $res->[2];
}

1;
# ABSTRACT:
