use v6;
use SVG::Plot;

class SVG::Plot::Pie is SVG::Plot;

has $.start-angle = 0;

multi method plot-coordinate-system() { (); }
multi method plot-x-labels() { (); }
multi method y-ticks($max_y, $scale_y) { (); }

multi method plot(:$full = True, :$pie!) {
    if @.values !== 1 {
        warn "Can only plot one data set in pie charts ({+@.values} given)";
    }
    my @d         := @( @.values[0]);
    my $step       = 2.0 * pi / [+] @d;
    if 0 > [min] @d {
        die "ERROR: can't plot pie chart with negative values";
    }
    my $prev-angle = $!start-angle;
    my $cr         = 0.35 * ($.plot-width min $.plot-height);
    my $cx         = 0.5 * $.plot-width;
    my $cy         = 0.5 * $.plot-height;
    my @svg = gather for @d.kv -> $i, $v {
        my $angle = $prev-angle + $v * $step;
        my @items = gather {
            take $.arc(
                :start($prev-angle),
                :end($angle),
                :r($cr),
                :stroke<black>,
                :color(@.colors[$i % *]),
            );
            my $legend-angle = 0.5 * ($prev-angle + $angle);

            my $incr = $i % 2 ?? 0.3 !! 0;

            take 'line' => [
                :style('stroke: grey; stroke-width: 1.2'),
                :x1($cx + 1.1  * $cr * cos($legend-angle)),
                :y1($cy + 1.1  * $cr * sin($legend-angle)),
                :x2($cx + (1.35 + $incr) * $cr * cos($legend-angle)),
                :y2($cy + (1.35 + $incr) * $cr * sin($legend-angle)),
            ];

            my ($text-anchor, $base-alignment);
            given cos($legend-angle) {
                if .abs < 0.4 {
                    $text-anchor = 'middle';
                } else {
                    $text-anchor = $_ > 0 ?? 'start' !! 'end';
                }
            }
            given sin($legend-angle) {
                if .abs < 0.4 {
                    $base-alignment = 'cenral';
                } else {
                    $base-alignment = $_ < 0 ?? 'top' !! 'bottom';
                }
            }


            take 'text' => [
                :x($cx + (1.5 + $incr) * $cr * cos($legend-angle)),
                :y($cy + (1.5 + $incr) * $cr * sin($legend-angle)),
                :text-anchor($text-anchor),
                :dominant-baseline($base-alignment),
                :font-size($.legend-font-size),
                @.labels[$i],
            ] if defined @.labels[$i];
        }
        take $.linkify($i, @items);

        $prev-angle = $angle;
    }
    if defined $.title {
        @svg.push: 'text' => [
            :x($.plot-width / 2),
            :y(-0.5 * ($.height - $.plot-height)),
            :text-anchor<middle>,
            :font-size(1.5 * $.legend-font-size),
            $.title,
        ];
    }
    my $tx = 0.5 * ($.width - $.plot-width);
    my $ty = 0.75 * ($.height - $.plot-height);
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
            :style('fill: none; stroke: black; stroke-width: 2'),
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
