use v6;
BEGIN {
    @*INC.push: '../lib', 'lib',
                '../../svg/lib','../svg/lib',
                '../../Text--CSV/lib/',
                '../../Text--CSV/';
}
use SVG;
use SVG::Plot;
use Text::CSV::Simple;

my $f = open('../../../rakudo/docs/spectest-progress.csv');
my $csv = Text::CSV::Simple.new;
$csv.parse_as_colnames($f.get) or die "can't parse column names";
warn $csv.colnames.perl;

my $line;
my (@date, @pass, @fail, @todo, @skip);
while $line = $f.get {
    unless $csv.parse($line) {
        warn "Can't parse line «$line»";
        next;
    }
    @date.push: $csv.field('date');
    @pass.push: $csv.field('pass');
    @fail.push: $csv.field('fail');
    @todo.push: $csv.field('todo');
    @skip.push: $csv.field('skip');
}

my $svg = SVG::Plot.new(
        :width(600),
        :height(550),
        :plot-height(400),
        :fill-width(1),
        :values([@pass], [@fail], [@todo], [@skip]),
        :labels(@date),
        :max-x-labels(20),
        :y-tick-step(-> $m { 10 ** floor(log10($m)) / 2 }),
    ).plot();

say SVG.serialize($svg);

# vim: ft=perl6
