
class SVG::Plot {
    has $.height        = 200;
    has $.width         = 300;
    has $.fill-width    = 0.80;
    has $.label-font-size     = 14;
    has $.plot-width    = $.width  * 0.80;
    has $.plot-height   = $.height * 0.65;

    has $.y-tick-step   = -> $max_y {
        10 ** floor(log10($max_y)) / 5
    }

    has $.max-x-labels  = $.plot-width / (1.5 * $.label-font-size);
    has $.max-y-labels  = $.plot-height / (2  * $.label-font-size);

    has $.label-spacing = ($.height - $.plot-height) / 20;

    method plot(@data, @labels = @data.keys, :$full = True) {
        my $label-skip = ceiling(@data / $.max-x-labels);
        my $max_x = +@data;
        my $max_y = [max] @data;

        my $step_x = $.plot-width  / $max_x;
        my $step_y = $.plot-height / $max_y;

        my @svg_d = gather {
            for @data.keys Z @data.values Z @labels -> $k, $v, $l {
                take 'rect' => [
                    :y(-$v * $step_y),
                    :x($k * $step_x),
                    :width($.fill-width * $step_x),
                    :height($v * $step_y),
                    :style<fill:blue>,
                ];

                if $k !% $label-skip {
                    # note that the rotation is applied first,
                    # so we have to  transform our 
                    # coordinates first: 
                    # x -> - y 
                    # y ->   x
                    my $t-offset = 0.5 * ($step_x - $.label-font-size);
                    take 'text' => [
                        :transform('rotate(90)'),
                        :y(-$k * $step_x - $t-offset),
                        :x($.label-spacing),
                        :font-size($.label-font-size),
                        ~$l,
                    ];
                }

            }
            self!y-ticks($max_y, $step_y);
        }

        my $x-trafo = 0.8 * ($.width - $.plot-width);
        my $y-trafo = $.plot-height + 0.3 * ($.height - $.plot-height);
        my $trafo = "translate($x-trafo,$y-trafo)";

        my @svg = 'g' => [
            :transform($trafo),
            @svg_d,
            'line' => [
                :x1(0),
                :y1(0),
                :x2($.plot-width),
                :y2(0),
                :style('stroke:black; stroke-width: 2'),
            ],
            'line' => [
                :x1(0),
                :y1(0),
                :x2(0),
                :y2(-$.plot-height),
                :style('stroke:black; stroke-width: 2'),
            ],
        ];

        return $full
            ??  
                :svg([
                        :width($.width), :height($.height),
                        'xmlns' => 'http://www.w3.org/2000/svg',
                        'xmlns:svg' => 'http://www.w3.org/2000/svg',
                        @svg
                ])
            !! @svg;
    }

    method !y-ticks($max_y, $scale_y) {
        my $step = ($.y-tick-step).($max_y);
        loop (my $y = 0; $y <= $max_y; $y += $step) {
            take 'line' => [
                :x1(-$.label-spacing / 2),
                :x2( $.label-spacing / 2),
                :y1(-$y * $scale_y),
                :y2(-$y * $scale_y),
                :style('stroke:black; stroke-width: 1'),
            ];
            take 'text' => [
                :x(-$.label-spacing
                        - $.label-font-size * chars($max_y.Int) / 1.2
                       ),
                :y(-$y * $scale_y + $.label-font-size / 2),
                :font-size($.label-font-size),
                ~ $y,
            ];
        }
    }
}

=begin Pod

=head1 NAME

SVG::Plot - simple SVG bar charts

=head1 SYNOPSIS

    use SVG;
    use SVG::Plot

    my @data = (0..100).map: { sin($_ / 10) };
    my $svg = SVG::Plot.new( width => 400, height => 250, fill-width => 1)\
              .plot(@data);
    say SVG.serialize($svg);

=end Pod

# vim: ft=perl6
