use SVG::Box;

enum SVG::Plot::AxisPosition <Zero SmallestValue LargestValue>;

class SVG::Plot;
has $.height            = 300;
has $.width             = 500;
has $.fill-width        = 0.80;
has $.label-font-size   = 12;
has $.legend-font-size  = $.label-font-size;

has @.legends is rw;
has @.values  is rw;
has @.x       is rw;    # only used in 'xy' variants
has @.labels  is rw = @.values[0].keys;
has @.links   is rw;

has $.plot-width        = $.width  * 0.80;
has $.plot-height       = $.height * (@.legends ?? 0.5 !! 0.65);

has $.title             = '';

has &.x-tick-step       = -> $max {
    10 ** $max.log10.floor  / 2
}

has &.y-tick-step       = -> $max {
    10 ** $max.log10.floor  / 2
}

has $.max-x-labels      = $.plot-width / (1.5 * $.label-font-size);

has $.label-spacing     = ($.height - $.plot-height) / 20;

has @.colors = <#3333ff #ffdd66 #aa2222 #228844 #eebb00 #8822bb>;

multi method plot(:$full = True, :$stacked-bars!) {

    my $label-skip = ceiling(@.values[0] / $.max-x-labels);
    my $max_x      = @.values[0].elems;

    # maximum value of the sum over each column
    my $max_y      =  [max] @.values[0].keys.map: {
        [+] @.values.map: -> $a { $a[$_] }
    };
    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / $max_x;
    my $step_y     = $.plot-height / $max_y;

    my @svg_d = gather {
        my $bar-width = $.fill-width * $step_x;
        for @.values[0].keys Z @.labels -> $k, $l {
            my $y-offset  = 0;
            for ^$datasets -> $d {
                my $v = @.values[$d][$k];
                my $p = 'rect' => [
                    :y(-$v * $step_y - $y-offset),
                    :x($k * $step_x),
                    :width($bar-width),
                    :height($v * $step_y),
                    :style("fill:{ @.colors[$d % *] }; stroke: none"),
                ];
                $y-offset += $v * $step_y;
                take $.linkify($k, $p);
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks(0, $max_y, $step_y);
    }

    my $svg = $.apply-standard-transform(
        @svg_d,
        @.eyecandy(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$bars!) {

    my $label-skip = ceiling(@.values[0] / $.max-x-labels);
    my $max_x      = @.values[0].elems;
    my $max_y      = [max] @.values.map: { [max] @($_) };

    # the minimum is only interesting if it's smaller than 0.
    # if all the values are non-negative, the bars should still start
    # at 0
    my $min_y      = ([min] @.values.map: { [min] @($_) }) min 0;

    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / $max_x;
    my $step_y     = $.plot-height / ($max_y - $min_y);

    my @svg_d = gather {
        my $bar-width = $.fill-width * $step_x / $datasets;
        for @.values[0].keys Z @.labels -> $k, $l {
            for ^$datasets -> $d {
                my $v = @.values[$d][$k];
                my ($y, $h) = (($v - $min_y) * $step_y, $v * $step_y);
                if $h < 0 {
                    $y = abs($min_y * $step_y);
                    $h = abs($v * $step_y);
                }
                my $p = 'rect' => [
                    :y(-$y),
                    :x($k * $step_x + $d * $bar-width),
                    :width($bar-width),
                    :height(abs($h)),
                    :style("fill:{ @.colors[$d % *] }"),
                ];
                take $.linkify($k, $p);
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks($min_y, $max_y, $step_y);
    }

    my $svg = $.apply-standard-transform(
        @svg_d,
        @.eyecandy(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$points!) {

    my $label-skip = ceiling(@.values[0] / $.max-x-labels);
    my $max_x      = @.values[0].elems;
    my $max_y      = [max] @.values.map: { [max] @($_) };
    my $min_y      = [min] @.values.map: { [min] @($_) };
    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / $max_x;
    my $step_y     = $.plot-height / ($max_y - $min_y);

    my @svg_d = gather {
        for @.values[0].keys Z @.labels -> $k, $l {
            for ^$datasets -> $d {
                my $v = @.values[$d][$k];
                my $p = 'circle' => [
                    :cy(-($v-$min_y) * $step_y),
                    :cx(($k + 0.5) * $step_x),
                    :r(3),
                    :style("fill:{ @.colors[$d % @.colors.elems] }"),
                ];
                take $.linkify($k, $p);
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks($min_y, $max_y, $step_y);
    }

    my $svg = $.apply-standard-transform(
        @svg_d,
        @.eyecandy(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$xy-points!) {
    my $label-skip = ceiling(@.values[0] / $.max-x-labels);

    my $max_x      = [max] @.x;
    my $min_x      = [min] @.x;

    my $max_y      = [max] @.values.map: { [max] @($_) };
    my $min_y      = [min] @.values.map: { [min] @($_) };

    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / ($max_x - $min_x);
    my $step_y     = $.plot-height / ($max_y - $min_y);

    my @svg_d = gather {
        for @.values[0].keys -> $k {
            for ^$datasets -> $d {
                my $v = @.values[$d][$k];
                my $x = @.x[$k];

                my $p = 'circle' => [
                    :cy(-($v-$min_y) * $step_y),
                    :cx(($x - $min_x) * $step_x),
                    :r(3),
                    :style("fill:{ @.colors[$d % @.colors.elems] }"),
                ];
                take $.linkify($k, $p);
            }
        }

        $.x-ticks($min_x, $max_x, $step_x);
        $.y-ticks($min_y, $max_y, $step_y);
    }

    my $svg = $.apply-standard-transform(
        @svg_d,
        @.eyecandy(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$xy-lines!) {
    my $label-skip = ceiling(@.values[0] / $.max-x-labels);

    my $max_x      = 40;
    my $min_x      = [min] @.x;

    if $max_x == $min_x {
        die "There's just one x value ($max_x), refusing to plot\n";
    }

    my $max_y      = 15;
    my $min_y      = [min] @.values.map: { [min] @($_) };

    if $max_y == $min_y {
        die "There's just one y value ($max_x), refusing to plot\n";
    }

    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / ($max_x - $min_x);
    my $step_y     = $.plot-height / ($max_y - $min_y);

    my @svg_d = gather {
        for ^$datasets -> $d {
            my ($prev-x, $prev-y);
            for @.values[0].keys -> $k {
                my $v = @.values[$d][$k];
                my $x = @.x[$k];
                if defined $prev-x {
                    my $p = 'line' => [
                        :x1($prev-x),
                        :x2(($x - $min_x) * $step_x),
                        :y1($prev-y),
                        :y2(-($v-$min_y) * $step_y),
                        :style("stroke:{ @.colors[$d % @.colors.elems] }; stroke-width: 1.5"),
                    ];
                    take $.linkify($k, $p);
                }
                $prev-x = ($x - $min_x) * $step_x;
                $prev-y = -($v-$min_y) * $step_y;
            }
        }

        $.x-ticks($min_x, $max_x, $step_x);
        $.y-ticks($min_y, $max_y, $step_y);
    }

    my $svg = $.apply-standard-transform(
        @svg_d,
        @.eyecandy(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$lines!) {

    my $label-skip = ceiling(@.values[0] / $.max-x-labels);
    my $max_x      = @.values[0].elems;
    my $max_y      = [max] @.values.map: { [max] @($_) };
    my $min_y      = [min] @.values.map: { [min] @($_) };
    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / $max_x;
    my $step_y     = $.plot-height / ($max_y - $min_y);

    my @svg_d = gather {
        for ^$datasets -> $d {
            my @previous-coordinates;
            for @.values[0].keys Z @.labels -> $k, $l {
                my $v = @.values[$d][$k];
                my @coord = ($k + 0.5) * $step_x, - ($v - $min_y) * $step_y;
                if @previous-coordinates {
                    my $p = 'line' => [
                        :x1(@previous-coordinates[0]),
                        :y1(@previous-coordinates[1]),
                        :x2(@coord[0]),
                        :y2(@coord[1]),
                        :style("stroke:{ @.colors[$d % @.colors.elems] }; stroke-width: 1.5"),
                    ];
                    take $.linkify($k, $p);
                }
                @previous-coordinates = @coord;
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks($min_y, $max_y, $step_y);
    }

    my $svg = $.apply-standard-transform(
        @svg_d,
        @.eyecandy(),
    );

    my $lb;
    if @.legends {
        $lb = $.plot-legend-box();
        $lb = self.apply-coordinate-transform(
            @($lb.svg),
            translate   => (($.width - $lb.width) / 2, $.height - $lb.height - 5),
        );
    } else {
        $lb = [];
    }
    @.wrap-in-svg-header-if-necessary($svg, $lb, :wrap($full));
}

method y-ticks($min_y, $max_y, $scale_y, $x = 0) {
    my $step = (&.y-tick-step).($max_y - $min_y);
    my $y_anchor = ($min_y / $step).Int * $step;

    loop (my $y = $y_anchor; $y <= $max_y; $y += $step) {
        take 'line' => [
            :x1($x - $.label-spacing / 2),
            :x2($x + $.label-spacing / 2),
            :y1(-($y - $min_y) * $scale_y),
            :y2(-($y - $min_y) * $scale_y),
            :style('stroke:black; stroke-width: 1'),
        ];
        take 'text' => [
            :x($x - 1.5 * $.label-spacing),
            :y(-($y - $min_y) * $scale_y),
            :font-size($.label-font-size),
            :text-anchor<end>,
            :dominant-baseline<middle>,
            ~ $y,
        ];
    }
}

method x-ticks($min_x, $max_x, $scale_x, $y = 0) {
    my $step = (&.x-tick-step).($max_x - $min_x);
    my $x_anchor = ($min_x / $step).Int * $step;

    loop (my $x = $x_anchor; $x <= $max_x; $x += $step) {
        take 'line' => [
            :y1($y - $.label-spacing / 2),
            :y2($y + $.label-spacing / 2),
            :x1(($x - $min_x) * $scale_x),
            :x2(($x - $min_x) * $scale_x),
            :style('stroke:black; stroke-width: 1'),
        ];
        take 'text' => [
            :y($y + 1.5 * ($.label-spacing + $.label-font-size)),
            :x(($x - $min_x) * $scale_x),
            :font-size($.label-font-size),
            :text-anchor<middle>,
            :dominant-baseline<middle>,
            ~ $x,
        ];
    }
}

method plot-x-labels(:$label-skip, :$step_x) {
    for @.values[0].keys Z @.labels -> $k, $l {
        if $k !% $label-skip {
            # note that the rotation is applied first,
            # so we have to  transform our
            # coordinates first:
            # x ->   y
            # y -> - x
            my $t = 'text' => [
                :transform('rotate(-90)'),
                :y(($k + 0.5 * $.fill-width) * $step_x),
                :x(-$.label-spacing),
                :font-size($.label-font-size),
                :dominant-baseline<middle>,
                :text-anchor<end>,
                ~$l,
            ];
            take $.linkify($k, $t);
        }
    }
}

# plots coordinate system, title etc.
multi method eyecandy() {
    @.plot-coordinate-system,
    @.plot-title,
}

multi method plot-coordinate-system() {
    # RAKUDO: can't use explicit return with a flattening list
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
    ];
}

multi method plot-title() {
#    return SVG::Box.new(
#
#    );
    return 'text' => [
        :x($.width * 0.5),
        :y(-$.plot-height - 0.1 * ($.height - $.plot-height) ),
        :text-anchor<middle>,
        $.title,
    ];
}

multi method apply-standard-transform(*@things) {
    $.apply-coordinate-transform(
        @things,
        translate   => (
            0.8 * ($.width - $.plot-width),
            $.plot-height + (@.legends ?? 0.2 !! 0.35)
            * ($.height - $.plot-height)
        ),
    );

}

multi method apply-coordinate-transform(*@things, :@translate) {
    return 'g' => [
        :transform("translate({@translate[0]},{@translate[1]})"),
        @things,
    ]
}

method linkify($key, *@things) {
    my $link = @.links[$key];
    defined($link)
        ?? ('a' => [
                'xlink:href' => $link,
                :target<_top>,
                @things
            ])
        !! @things;
}

multi method plot-legend-box() {
    my $height = 10 + 1.4 * $.legend-font-size * @.legends;
    my $width  = 10 + 0.7 * $.legend-font-size
                          * (([max] @.legends>>.chars) + 2);
    return unless @.legends;

    my $svg = gather {
        take 'rect' => [
            x       => 0,
            y       => 0,
            height  => $height,
            width   => $width,
            style   => 'stroke: black; strok-width: 0.5; fill: none',
        ];
        for @.legends.kv -> $i, $l {
            take 'rect' => [
                x       => 10,
                y       => 5 + 1.4 * $i * $.legend-font-size,
                height  => $.legend-font-size,
                width   => $.legend-font-size,
                style   => "stroke: black; stroke-width: 0.2; fill: "
                           ~ @.colors[$i % *] ~ ";",
            ];
            take 'text' => [
                x       => 2 * $.legend-font-size,
                y       => 5 + 1.4 * $i * $.legend-font-size
                           + 0.5 * $.legend-font-size,
                dominant-baseline   => 'central',
                $l,
            ];
        }
    }

    return SVG::Box.new(
        x       => 0,
        y       => 0,
        svg     => $svg,
        height  => $height,
        width   => $width,
        name    => 'legend',
    );
}

method wrap-in-svg-header-if-necessary(*@things, :$wrap) {
    return $wrap
        ??
            :svg([
                    :width($.width), :height($.height),
                    'xmlns' => 'http://www.w3.org/2000/svg',
                    'xmlns:svg' => 'http://www.w3.org/2000/svg',
                    'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                    @things
            ])
        !!@things;
}

=begin Pod

=head1 NAME

SVG::Plot - simple SVG bar charts

=head1 VERSION

$very_early

=head1 SYNOPSIS

    use SVG;
    use SVG::Plot;

    my @d1 = (0..100).map: { sin($_ / 10.0) };
    my @d2 = (0..100).map: { cos($_ / 10.0) };
    my $svg = SVG::Plot.new(
                width  => 400,
                height => 250,
                values => ([@d1], [@d2]),
                title  => 'sin(x/10), cos(x/10)',
            ).plot(:lines);
    say SVG.serialize($svg);


=head1 DESCRIPTION

SVG::Plot turns a set of data points (and optionally labels) into a data
structure which Carl Mäsak's module L<SVG> serializes into SVG, and displays a
bar chart of the data.

See L<http://perlgeek.de/blog-en/perl-6/svg-adventures.html> for the initial
announcement and future plans.

Note that the module itself does not depend on SVG.pm, only the examples (and
maybe in future the tests).

=head1 A WORD OF WARNING

Please note that the interface of this module is still in flux, and might
change without further notice. If you actually use it, send the author an
email to inform him, maybe he'll try to keep the interface backwards
compatible, or notify you on incompatible changes.

=head1 METHODS

=head2 new(*%options)
Constructs a L<Plot::SVG> object. You can set various attributes as options,
see their documentation below. No attribute is mandatory.

=head2 multi method plot(:$$type!, :$full = True)
If the argument C<$!full> is provided, the returned data structure contains
only the body of the SVG, not the C<< <svg xmlns=...> >> header.

Each multi method renders one type of chart, and has a mandatory named
parameter with the name of the type. Currently available are C<bars>,
C<stacked-bars>, C<lines> and C<points>.

=head1 Attributes

The following attributes can be set with the C<new> constructor, and can be
queried later on (those marked with C<is rw> can also be set later on).

=head2 @.values is rw
The values to be plotted

=head2 @.labels is rw
The labels printed below the bars. Note that this must be either left empty
(in which case C<@.values.keys> is used as a default), or of the same length
as C<@.values>. To suppress printing of labels just set them all to the empty
string, C<$svg.labels = ('' xx $svg.values.elems)>.

=head2 @.links is rw
If some values of @.links are set to defined values, the corresponding bars
and labels will be turned into links

=head2 $.width
=head2 $.height

The overall size of the image (what is called the I<canvas> in SVG jargon).
SVG::Plot tries not to draw outside the canvas.

=head2 $.plot-width
=head2 $.plot-height

The size of the area to which the chart is plotted (the rest is taken up by
ticks, labels and in future probably captions). The behaviour is undefined if
C<< $.plot-width < $.width >> or C<< $.plot-height >>.

Note that if you chose C<$.plot-width> or C<$.plot-height> too big in
comparison to C<$.width> and C<$.height>, label texts and ticks might
exceed the total size, and be either clipped to or drawn outside the canvas,
depending on your SVG renderer.

=head2 $.fill-width
(Might be renamed to a more meaning name in future) For each bar in the bar
chart a certain width is allocated, but only a ratio of C<$.fill-width>  is
actually filled with a bar. Set to value between 0 and 1 to get spaces between
your bars, or to 1 if you don't  want spaces.

=head2 $.label-font-size
Font size for the axis labels

=head2 &.y-tick-step
Closure which computes the step size in which ticks and labels on the y axis
are drawn. It receives the maximal C<y> value as a single positional argument.

=head2 &.x-tick-step
Closure which computes the step size in which ticks and labels on the x axis
are drawn. It receives the maximal C<x> value as a single positional argument.

=head2 $.max-x-labels
Maximal number of plotted labels in C<x> direction. If you experience
overlapping labels you might set this to a smaller value. The default is
dependent on C<$.plot-width> and C<$.label-font-size>.

=head2 $.label-spacing

Distance between I<x> axis and labels. Also affects width of I<y> ticks and
distance of labels and I<y> ticks.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 by Moritz Lenz and the SVG::Plot contributors (see file
F<AUTHORS>), all rights reserved.

You may distribute, use and modify this module under the terms of the Artistic
License 2.0 as published by The Perl Foundation. See the F<LICENSE> file for
details.

The example code in the F<examples> directory and the examples from the
documentation can be used, modified and distributed freely without any
restrictions (think "public domain", except that by German law the author
can't place things into the public domain).

=head1 WARRANTY EXCLUSION

This software is provided as-is, in the hope that it is useful to somebody.
Not fitness for a particular purpose or any kind of guarantuee of
functionality is implied.

No responsibilities are taken by author to the extend allowed by applicable
law.

=end Pod

# vim: ft=perl6
