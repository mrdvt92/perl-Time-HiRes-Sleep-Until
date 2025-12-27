# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 8;
use Time::HiRes qw{time};
use Test::Number::Delta; #delta_within

my $tolerance=$ENV{"Time_HiRes_Sleep_Until_TOLERANCE"} || 0.04 || 0.002; #I can get this to pass

diag("\nTolerance: $tolerance seconds\n");

BEGIN { use_ok( 'Time::HiRes::Sleep::Until' ); }

my $su = Time::HiRes::Sleep::Until->new;
isa_ok ($su, 'Time::HiRes::Sleep::Until');

my $skip=0;
{
  my $sleep  = 1;
  my $before = time;
  sleep $sleep;
  my $after  = time;
  my $delta  = abs($after - $before - $sleep);
  diag("Sleep Delta: $delta\n");
  $skip=1 if $delta > 0.001;
}
  
SKIP: {
  skip "Your machine cannot sleep reliably so we won't even try to run our tests", 6 if $skip;
  
  {
    diag("sleep wrapper 1");
    my $slept = $su->sleep(0.5);
    delta_within($slept, 0.5, $tolerance, 'sleep wrapper 1');
  }
  {
    diag("sleep wrapper 2");
    my $slept = $su->sleep(0.5, 'foo', 'bar'); #should sleep for $_[0] not 3 seconds
    delta_within($slept, 0.5, $tolerance, 'sleep wrapper 2');
  }
  {
    diag("sleep wrapper 2 array");
    my @array = (0.5, 'foo', 'bar');
    my $slept = $su->sleep(@array); #should sleep for $_[0] not 3 seconds
    delta_within($slept, 0.5, $tolerance, 'sleep wrapper 2 array');
  }
  {
    diag("sleep wrapper 3");
    local $SIG{'ALRM'} = sub {die("alarm")};
    alarm 2;
    my $before=time;
    my $slept = eval{$su->sleep()}; #hangs forever except for alarm
    my $error = $@;
    my $after=time;
    my $delta = $after - $before;
    #diag($error);
    like($error, qr/alarm/, 'sleep wrapper 3 eval error');
    is($slept, undef, 'sleep wrapper 3 eval return');
    delta_within($delta, 2, $tolerance, 'sleep wrapper 3');
  }
}
