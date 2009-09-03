class SVG::Plot;
has $.height            = 200;
has $.width             = 300;
has $.fill-width        = 0.80;
has $.label-font-size   = 14;
has $.plot-width        = $.width  * 0.80;
has $.plot-height       = $.height * 0.65;

has &.y-tick-step       = -> $max_y {
    10 ** floor(log10($max_y)) / 5.0
}

has $.max-x-labels      = $.plot-width / (1.5 * $.label-font-size);

has $.label-spacing     = ($.height - $.plot-height) / 20;

has @.values is rw;
has @.labels is rw = @.values[0].keys;
has @.links  is rw;

has @.colors = <blue red green yellow>;

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
                take self!linkify($k, $p);
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks($max_y, $step_y);
    }

    my $svg = $.apply-coordinate-transform(
        @svg_d,
        @.coordinate-system(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$bars!) {

    my $label-skip = ceiling(@.values[0] / $.max-x-labels);
    my $max_x      = @.values[0].elems;
    my $max_y      = [max] @.values.map: { [max] @($_) };
    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / $max_x;
    my $step_y     = $.plot-height / $max_y;

    my @svg_d = gather {
        my $bar-width = $.fill-width * $step_x / $datasets;
        for @.values[0].keys Z @.labels -> $k, $l {
            for ^$datasets -> $d {
                my $v = @.values[$d][$k];
                my $p = 'rect' => [
                    :y(-$v * $step_y),
                    :x($k * $step_x + $d * $bar-width),
                    :width($bar-width),
                    :height($v * $step_y),
                    :style("fill:{ @.colors[$d % *] }"),
                ];
                take self!linkify($k, $p);
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks($max_y, $step_y);
    }

    my $svg = $.apply-coordinate-transform(
        @svg_d,
        @.coordinate-system(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

multi method plot(:$full = True, :$points!) {

    my $label-skip = ceiling(@.values[0] / $.max-x-labels);
    my $max_x      = @.values[0].elems;
    my $max_y      = [max] @.values.map: { [max] @($_) };
    my $datasets   = +@.values;

    my $step_x     = $.plot-width  / $max_x;
    my $step_y     = $.plot-height / $max_y;

    my @svg_d = gather {
        for @.values[0].keys Z @.labels -> $k, $l {
            for ^$datasets -> $d {
                my $v = @.values[$d][$k];
                my $p = 'circle' => [
                    :cy(-$v * $step_y),
                    :cx(($k + 0.5) * $step_x),
                    :r(3),
                    :style("fill:{ @.colors[$d % *] }"),
                ];
                take self!linkify($k, $p);
            }
        }

        $.plot-x-labels(:$step_x, :$label-skip);
        $.y-ticks($max_y, $step_y);
    }

    my $svg = $.apply-coordinate-transform(
        @svg_d,
        @.coordinate-system(),
    );

    @.wrap-in-svg-header-if-necessary($svg, :wrap($full));
}

method y-ticks($max_y, $scale_y) {
    my $step = (&.y-tick-step).($max_y);
    loop (my $y = 0; $y <= $max_y; $y += $step) {
        take 'line' => [
            :x1(-$.label-spacing / 2),
            :x2( $.label-spacing / 2),
            :y1(-$y * $scale_y),
            :y2(-$y * $scale_y),
            :style('stroke:black; stroke-width: 1'),
        ];
        take 'text' => [
            :x(- 1.5 * $.label-spacing),
            :y(-$y * $scale_y),
            :font-size($.label-font-size),
            :text-anchor<end>,
            :dominant-baseline<middle>,
            ~ $y,
        ];
    }
}

method plot-x-labels(:$label-skip, :$step_x) {
    for @.values[0].keys Z @.labels -> $k, $l {
        if $k !% $label-skip {
            # note that the rotation is applied first,
            # so we have to  transform our
            # coordinates first:
            # x -> - y
            # y ->   x
            my $t = 'text' => [
                :transform('rotate(90)'),
                :y((-$k - 0.5 * $.fill-width) * $step_x),
                :x($.label-spacing),
                :font-size($.label-font-size),
                :dominant-baseline<middle>,
                ~$l,
            ];
            take self!linkify($k, $t);
        }
    }
}

method coordinate-system() {
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

multi method apply-coordinate-transform(*@things) {
    my $x-trafo = 0.8 * ($.width - $.plot-width);
    my $y-trafo = $.plot-height + 0.3 * ($.height - $.plot-height);
    my $trafo = "translate($x-trafo,$y-trafo)";

    return 'g' => [
        :transform($trafo),
        @things,
    ];
}

method !linkify($key, $thing) {
    my $link = @.links[$key];
    defined($link)
        ?? ('a' => [
                'xlink:href' => $link,
                :target<_top>,
                $thing
            ])
        !! $thing;
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
    use SVG::Plot

    my @data = (0..100).map: { sin($_ / 10) };
    my $svg = SVG::Plot.new(
                width => 400,
                height => 250,
                values => @data,
            ).plot(:stacked-bars);
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
C<stacked-bars>, and C<points>.

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
