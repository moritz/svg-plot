use v6;

BEGIN { @*INC.push: '../svg/lib', 'lib' }

use SVG;
use SVG::Plot;

my @data = 5, 6, 4, 3, 8, 12, 0, 0, 3, 7;
my $svg = SVG::Plot.new(width => 300, height => 200).plot(@data);

say SVG.serialize($svg);


# vim: ft=perl6 sw=4 ts=4 expandtab
