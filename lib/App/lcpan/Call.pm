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
        max_age => {
            summary => 'Maximum index age (in seconds)',
            schema => 'duration',
            'x.perl.coerce_to' => 'int(secs)',
            description => <<'_',

If unspecified, will look at `LCPAN_MAX_AGE` environment variable. If that is
also undefined, will default to 14 days.

_
        },
        argv => {
            schema => ['array*', of=>'str*'],
            default => [],
        },
    },
    result_naked => 1,
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
        my $max_age = $args{max_age} // $ENV{LCPAN_MAX_AGE} // 14*86400;
        my $max_age_in_days = sprintf("%g", $max_age / 86400);
        if ((time - $stats->{raw_last_index_time}) > $max_age) {
            die "lcpan index is over $max_age_in_days day(s) old, ".
                "please refresh it first with 'lcpan update'\n";
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
