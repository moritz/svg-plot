use v6;
BEGIN {
    @*INC.push: '../lib', '../../svg/lib',
                'lib', '../svg/lib';
}
use SVG;
use SVG::Plot;

grammar AccessLog {
    token TOP {
        ^ <ip>
          \s <dummy>
          \s <dummy>
          \s <date>
          \s <request>
          \s <status>
          \s <size>
          \s <referrer>
          \s <user_agent>
          $
    }
    regex ip {
        | <ipv4>
        | <ipv6>
    }

    token ipv4 {
             \d ** 1..3
        [ \. \d ** 1..3 ] ** 3
    }

    token ipv6 {
        <[0..9 :]>+     # need a better regex
    }

    token dummy { '-' }

    token date {
        '[' ~  ']'
            [
            ( \d\d ) '/' ( \w\w\w ) '/' ( \d\d\d\d )
            <-[ \] ]>+
            ]
    }

    token request { \" <-[ " ]>* \" }

    token status { <[0..9]>+ }

    token size { <[0..9]>+ | <dummy> }

    token referrer { \" <-[ " ]>* \" }

    token user_agent {
        \" ~ \"
        [
            | <-[ " ]>
            | \\ \"
        ]*
    }
}


my $f = open('access.log');

my $line;


my %months = <Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec> Z 1..12;

my $prev_date;
my $prev_human_date;
my %user;
my @visitor_per_day;
my @dates;

while $line = $f.get {
    AccessLog.parse($line) or next;
    my $date = sprintf '%04d-%02d-%02d', $<date>[2],
                       %months{$<date>[1]}, $<date>[0];
    $prev_date //= $date;

    if $prev_date ne $date {
        @visitor_per_day.push:  +%user;
        @dates.push:            ~$prev_date;
        %user = ();
        $prev_date = $date;
    }


    %user{$<ip> ~ $<user_agent>}++;
}

my $svg = SVG::Plot.new(
        :width(600),
        :height(550),
        :plot-height(400),
        :fill-width(1),
        :title('Visitors per day on perl6.org'),
        :values([@visitor_per_day]),
        :labels(@dates),
        :title<accesses on perl6.org>,
    ).plot(:bars);

say SVG.serialize($svg);

# vim: ft=perl6
