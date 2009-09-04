use SVG::Plot;
class SVG::Plot::Pie is SVG::Plot;

multi method plot-coordinate-system() { (); }
multi method plot-x-labels() { (); }
multi method y-ticks($max_y, $scale_y) { (); }

multi method plot(:$full = True, :$pie!) {
    if @.values !== 1 {
        warn "Can only plot one data set in pie charts ({+@.values} given)";
    }
    my @d         := @( @.values[0]);
    my $step       = 2.0 * pi / [+] @d;
    my $prev-angle = 0;
    my @svg = gather for @d.kv -> $i, $v {
        my $angle = $prev-angle + $v * $step;
        take $.arc(
            :start($prev-angle),
            :end($angle),
            :color(@.colors[$i % *]),
            :stroke<black>,
        );
        $prev-angle = $angle;
    }
    my $tx = 0.5 * ($.width - $.plot-width);
    my $ty = 0.5 * ($.height - $.plot-height);
    return @.wrap-in-svg-header-if-necessary(
        'g' => [
            :transform("translate($tx,$ty)"),
            @svg,
        ],
        :wrap($full)
    );
}

method arc(
        $cx = 0.5 * $.plot-width,
        $cy = 0.5 * $.plot-height,
        $r = 0.5 * ($.plot-width min $.plot-height),
        :$start!,
        :end($phi)!,
        :$color = 'red',
        :$stroke = 'none',
    ) {
    my @commands = 'M', $cx, $cy,
            'l', $r * cos($start), $r * sin($start),
            'A', $r, $r, 0,  + ($phi - $start > pi), 1,
                        $cx + $r * cos($phi), $cy + $r * sin($phi), "z";

    my $c = join ' ', @commands;
    return 'g' => [
        :stroke($stroke),
        :fill($color),
        path => [ :d($c) ],
    ];
}


# vim: ft=perl6
