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
my $line;
my (@date, @pass, @fail, @todo, @skip, @specskip);
while $line = $f.get {
    unless $csv.parse($line) {
        warn "Can't parse line «$line»";
        next;
    }
    @date.push: $csv.field('date').substr(0, 10);
    @pass.push: $csv.field('pass');
    @fail.push: $csv.field('fail');
    @todo.push: $csv.field('todo');
    @skip.push: $csv.field('skip');
    @specskip.push: $csv.field('spec')
            - [+] @pass[*-1], @fail[*-1], @todo[*-1], @skip[*-1];
}
my @data = [@pass], [@fail], [@todo], [@skip], [@specskip];

my $svg = SVG::Plot.new(
        :width(800),
        :height(550),
        :plot-height(400),
        :fill-width(1.01), # work a round a common SVG rendering bug
        :values(@data),
        :labels(@date),
        :max-x-labels(20),
        :colors<lawngreen red blue yellow lightgrey>,
    ).plot(:stacked-bars);

say SVG.serialize($svg);

# vim: ft=perl6
