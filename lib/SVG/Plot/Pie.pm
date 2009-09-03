use SVG::Plot;
class SVG::Plot::Pie is SVG::Plot;

multi method plot-coordinate-system() { (); }
multi method plot-x-labels() { (); }
multi method y-ticks($max_y, $scale_y) { (); }

# vim: ft=perl6
