package App::lcpan::Call;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(call_lcpan_script check_lcpan);

my %common_args = (
    max_age => {
        summary => 'Maximum index age (in seconds)',
        schema => 'duration',
        description => <<'_',

If unspecified, will look at `LCPAN_MAX_AGE` environment variable. If that is
also undefined, will default to 14 days.

_
    },
);

$SPEC{call_lcpan_script} = {
    v => 1.1,
    summary => '"Call" lcpan script',
    args => {
        %common_args,
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
        my $check_res = check_lcpan(%args);
        die "$check_res->[1]\n" unless $check_res->[0] == 200;
    }

    Perinci::CmdLine::Call::call_cli_script(
        script => 'lcpan',
        argv   => $args{'argv'},
    );
}

$SPEC{check_lcpan} = {
    v => 1.1,
    summary => "Check that local CPAN mirror exists and is fairly recent",
    description => <<'_',

Will return status 200 if `lcpan` script is installed (available from PATH),
local CPAN mirror exists, and is fairly recent and queryable. This routine will
actually attempt to run "lcpan stats-last-index-time" and return the result if
the result is 200 *and* the index is updated quite recently. By default "quite
recently" is defined as not older than 2 weeks or whatever LCPAN_MAX_AGE says
(in seconds).

_
    args => {
        %common_args,
    },
};
sub check_lcpan {
    require File::Which;
    require Perinci::CmdLine::Call;

    my %args;

    File::Which::which("lcpan")
          or die "lcpan is not available, please install it first\n";
    my $res = Perinci::CmdLine::Call::call_cli_script(
        script => 'lcpan',
        argv   => ['stats-last-index-time'],
    );
    return [412, "Can't 'lcpan stats': $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    my $stats = $res->[2];
    my $max_age = $args{max_age} // $ENV{LCPAN_MAX_AGE} // 14*86400;
    my $max_age_in_days = sprintf("%g", $max_age / 86400);
    my $age = time - $stats->{raw_last_index_time};
    my $age_in_days = sprintf("%g", $age / 86400);
    if ($age > $max_age) {
        return [412, "lcpan index is over $max_age_in_days day(s) old ".
                    "($age_in_days), please refresh it first with ".
                    "'lcpan update'"];
    }
    $res;
}

1;
# ABSTRACT:

=head1 ENVIRONMENT

=head2 LCPAN_MAX_AGE => int

Set the default of C<max_age>.
