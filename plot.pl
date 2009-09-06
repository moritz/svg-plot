use v6;

BEGIN { @*INC.push: '../svg/lib', 'lib' }

use SVG;
use SVG::Plot;
use SVG::Plot::Pie;

my @data1   = map *.abs, 5, 6, 4, -3, -7, 12, 1, 1, 3, 7;
my @data2   = 2, 8, 0, 5, 6, 7,  8, -1, -1, -3;
my @labels  = <the quick brown fox jumps over the lazy red dog>;
my $svg = SVG::Plot::Pie.new(
            width      => 400,
            height     => 350,
            values     => ([@data1], [@data2]),
            title      => 'Some data',
            :@labels,
            links => <http://en.wikipedia.org/wiki/The_quick_brown_fox_jumps_over_the_lazy_dog>,
        ).plot(:pie);

say SVG.serialize($svg);


# vim: ft=perl6 sw=4 ts=4 expandtab
