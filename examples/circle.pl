use SVG;
use SVG::Plot;

my $points = 50;
my @x  = (0..$points).for: { sin(2 * pi * $_ / $points) };
my @d1 = (0..$points).for: { 2 * cos(2 * pi * $_ / $points) };
my @d2 = (0..$points).for: { cos(2 * pi * $_ / $points) };
say SVG.serialize: SVG::Plot.new(
    width => 400,
    height => 250,
    :@x,
    values => ([@d1], [@d2]),
    title  => 'sin(x/10), cos(x/10)',
).plot(:xy-lines);
