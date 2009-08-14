
class SVG::Plot {
    has $.height = 200;
    has $.width  = 300;

    method plot(@data, :$full = True) {
        my $max_x = 0;
        my $max_y = 0;

        my @svg_d = gather {
            for @data.kv -> $k, $v {
                take 'rect' => [
                    :y(0),
                    :x($k * 40),
                    :width(35),
                    :height($v),
                    :style<fill:blue>,
                ];
                $max_x = ($k + 1) * 40;
                $max_y max= $v;
            }
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

# vim: ft=perl6
