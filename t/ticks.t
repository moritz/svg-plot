BEGIN { @*INC.push: 'lib', '../lib' };
use Test;

plan 1;

use SVG::Plot;

my $s = SVG::Plot.new();

ok ($s.tick-step).(200) % 5 == 0, 'SVG.tick-step produces a sensible value';

