use v6;
BEGIN {
    @*INC.unshift: '../lib', '../../svg/lib',
                'lib', '../svg/lib';
}
use SVG;
use SVG::Plot;
use SVG::Plot::Pie;
my %counts =
    moritz      => 1511,
    audreyt     =>  916,
    iblech      =>  548,
    lwall       =>  308,
    jnthn       =>  302,
    kyle        =>  271,
    pmichaud    =>  260,
    corion      =>  152,
    agentz      =>  148,
    putter      =>  145,
    Rest        => 2359,
    ;

my @c = %counts.sort: *.value;
my @values = @c>>.value;
my @names  = @c>>.key;

my $svg = SVG::Plot::Pie.new(
        width   => 400,
        height  => 300,
        values  => [$(@values)],
        labels  => @names,
        title   => 'Test suite committers',
    ).plot(:pie);
say SVG.serialize($svg);
