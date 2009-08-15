
class SVG::Plot {
    has $.height        = 200;
    has $.width         = 300;
    has $.fill-width    = 0.80;
    has $.font-size     = 14;
    has $.plot-width    = $.width  * 0.80;
    has $.plot-height   = $.height * 0.80;

    has $.max-labels    = $.plot-width / (1.5 * $.font-size);

    has $.label-spacing = ($.height - $.plot-height) / 20;

    method plot(@data, @labels = @data.keys, :$full = True) {
        my $label-skip = ceiling(@data / $.max-labels);
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
                    my $t-offset = 0.5 * ($step_x - $.font-size);
                    take 'text' => [
                        :transform('rotate(90)'),
                        :y(-$k * $step_x - $t-offset),
                        :x($.label-spacing),
                        :font-size($.font-size),
                        ~$l,
                    ];
                }

            }
            $max_x = +@data;
        }

        my $trafo = "translate(0,$.plot-height)";

        my @svg = 'g' => [
                :transform($trafo),
                @svg_d,
                ],
                'line' => [
                    :x1(0),
                    :y1($.height),
                    :x2($.width),
                    :y2($.height),
                    :style('stroke:black; stroke-width: 2'),
                ],
                'line' => [
                    :x1(0),
                    :y1(0),
                    :x2(0),
                    :y2($.height),
                    :style('stroke:black; stroke-width: 2'),
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
