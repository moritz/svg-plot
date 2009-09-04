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
    my $cr         = 0.35 * ($.plot-width min $.plot-height);
    my $cx         = 0.5 * $.plot-width;
    my $cy         = 0.5 * $.plot-height;
    my @svg = gather for @d.kv -> $i, $v {
        my $angle = $prev-angle + $v * $step;
        take $.arc(
            :start($prev-angle),
            :end($angle),
            :r($cr),
            :stroke<black>,
            :color(@.colors[$i % *]),
        );
        my $legend-angle = 0.5 * ($prev-angle + $angle);
        take 'line' => [
            :style('stroke: black; stroke-width: 1.2'),
            :x1($cx + 1.1 * $cr * cos($legend-angle)),
            :x2($cx + 1.3 * $cr * cos($legend-angle)),
            :y1($cy + 1.1 * $cr * sin($legend-angle)),
            :y2($cy + 1.3 * $cr * sin($legend-angle)),
        ];
        my $text-anchor;
        if abs(cos($legend-angle)) < 0.5 {
            $text-anchor = 'middle';
        } else {
            $text-anchor = cos($legend-angle) > 0 ?? 'start' !! 'end';
        }
        take 'text' => [
            :x($cx + 1.4 * $cr * cos($legend-angle)),
            :y($cy + 1.4 * $cr * sin($legend-angle)),
            :text-anchor($text-anchor),
            @.labels[$i],
        ] if defined @.labels[$i];

        $prev-angle = $angle;
    }
    my $tx = 0.5 * ($.width - $.plot-width);
    my $ty = 0.5 * ($.height - $.plot-height);
    return @.wrap-in-svg-header-if-necessary(
        'g' => [
            :transform("translate($tx,$ty)"),
            @svg,
        ],
        'rect' => [
            :x(0),
            :h(0),
            :height($.height),
            :width($.width),
            :style('fill: none; stroke: black; strok-width: 2'),
        ],
        :wrap($full)
    );
}

method arc(
        :$start!,
        :end($phi)!,
        :$cx = 0.5 * $.plot-width,
        :$cy = 0.5 * $.plot-height,
        :$r,
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
