use v6;

BEGIN { @*INC.push: '../svg/lib' }

use SVG;

my $width = 300;
my $height = 200;

my @data = (45, 40, 35, 0, 0, 0, 20);

my $max_x = 0;
my $max_y = 0;

my @svg_d = gather {
    for @data.kv -> $k, $v {
        take 'rect' => [
#            :transform<matrix(1,0,0,-1,0,100)>,
            :y(0),
            :x($k * 40),
            :width(35),
            :height($v),
            :style<fill:blue>,
        ];
        $max_x = $k * 40;
        $max_y max= $v;
    }
}

my @transformation = (
        $width / $max_x,    # scaling in x direction,
        0,                  # x-y skew
        0,                  # y-x skew
        -$height / $max_y,  # scaling in y direction,
                            # negative, since SVG defines the positive
                            # y axis downwards
        0,                  # translation x
        $height,            # translation y
);

my $trafo = 'matrix(' ~ @transformation.join(',') ~ ')';

my $svg = :svg([
    :wdith(220), :height(120),
    'xmlns:svg' => 'http://www.w3.org/2000/svg',
    :g([
        :transform($trafo),
        @svg_d,
    ]),
    'line' => [
        :x1(0),
        :y1($height),
        :x2($width),
        :y2($height),
        :style('stroke:black; stroke-width: 2'),
    ];
]);

say SVG.serialize($svg);


# vim: ft=perl6 sw=4 ts=4 expandtab
