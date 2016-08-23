use v6;
use lib '../lib', '../../svg/lib',
        'lib', '../svg/lib';
use SVG;
use SVG::Plot;

# cw: Sensible storage method
my @data1 = (
	# [x, y, mag]
	[  1,    5,    1],
	[  3,    6,    1],
	[  5,    4,    1],
	[  2,    2,    1],
);

my @data2 = (
	[ 2,   5, 0.5],
	[ 4,   4, 0.5],
	[ 3, 2.5, 0.5],
	[ 5,   4, 0.5],
);

my $svg = SVG::Plot.new(
    width   		=> 500,
    height  		=> 300,
    values  		=> [ $(@data1), $(@data2) ],
    title   		=> 'Bubbles!',
    min-y-axis 		=> 0
).plot(:bubbles);
say SVG.serialize($svg);
