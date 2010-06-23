BEGIN { @*INC.push: 'lib', '../lib' };
use Test;

plan 2;

use SVG::Plot;

my $s = SVG::Plot.new();

ok ($s.x-tick-step).(200) % 5 == 0, 'SVG.x-tick-step produces a sensible value';
ok ($s.y-tick-step).(200) % 5 == 0, 'SVG.y-tick-step produces a sensible value';

