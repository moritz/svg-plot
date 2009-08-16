
class SVG::Plot {
    has $.height            = 200;
    has $.width             = 300;
    has $.fill-width        = 0.80;
    has $.label-font-size   = 14;
    has $.plot-width        = $.width  * 0.80;
    has $.plot-height       = $.height * 0.65;

    has &.y-tick-step       = -> $max_y {
        10 ** floor(log10($max_y)) / 5
    }

    has $.max-x-labels      = $.plot-width / (1.5 * $.label-font-size);

    has $.label-spacing     = ($.height - $.plot-height) / 20;

    method plot(@data,
                @labels     = @data.keys,
                :$full      = True,
            ) {
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

=head2 method plot(@data, @labels = @data.keys, :$full = True)
Creates a data structure describing a bar chart. C<@data> should contain
numerical values, each of which maps to the height of a single bar.
C<@labels> contains the labels to be printed, and should contain the same
number of items as C<@data>. If C<@labels> is omitted, the values 0, 1, 2 etc.
are assumed as labels.

If the argument C<$!full> is provided, the returned data structure contains
only the body of the SVG, not the C<< <svg xmlns=...> >> header.

=head1 Attributes

The following attributes can be set with the C<new> constructor, and can be
queried later on

=head2 $.width
=head2 $.height

The overall size of the image (what is called the I<canvas> in SVG jargon).
SVG::Plot tries not to draw outside the canvas.

=head2 $.plot-width
=head2 $.plot-height

The size of the area to which the chart is plotted (the rest is taken up by
ticks, labels and in future probably captions). The behaviour is undefined if
C<< $.plot-width < $.width >> or C<< $.plot-height >>.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 by Moritz A. Lenz, all rights reserved

You may distribute, use and modify this module under the terms of the Artistic
License 2.0 as published by The Perl Foundation. See the F<LICENSE> file for
details.

=end Pod

# vim: ft=perl6
