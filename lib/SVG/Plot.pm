
class SVG::Plot {
    has $.height        = 200;
    has $.width         = 300;
    has $.fill-width    = 0.80;

    method plot(@data, :$full = True) {
        my $max_x = 0;
        my $max_y = 0;

        my @svg_d = gather {
            for @data.kv -> $k, $v {
                take 'rect' => [
                    :y(0),
                    :x($k),
                    :width($.fill-width),
                    :height($v),
                    :style<fill:blue>,
                ];
                $max_y max= $v;
            }
            $max_x = +@data;
        }

        my @transformation = (
                $.width / $max_x,   # scaling in x direction,
                0,                  # x-y skew
                0,                  # y-x skew
                -$.height / $max_y, # scaling in y direction,
                                    # negative, since SVG defines the
                                    # positive y axis downwards
                0,                  # translation x
                $.height,           # translation y
        );
        my $trafo = 'matrix(' ~ @transformation.join(',') ~ ')';

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
