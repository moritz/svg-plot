unit class SVG::Box;

has $.svg       is rw;
has $.width     is rw;
has $.height    is rw;
has $.x         is rw;
has $.y         is rw;

has $.name;

method move($x, $y = 0, *%rest) {
    return self.clone(
        svg =>  [
            transform   => "translate($x, $y)",
            $!svg ~~ Positional ?? @($!svg) !! $!svg,
        ],
        |%rest
    );
}

# vim: ft=perl6
