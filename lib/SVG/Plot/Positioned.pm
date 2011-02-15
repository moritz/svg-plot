enum SVG::Plot::Position <left right top bottom>;

class SVG::Plot::Positioned {
    has SVG::Plot::Position $.position is rw;

    method is-left()   { $.position == left   };
    method is-right()  { $.position == right  };
    method is-top()    { $.position == top    };
    method is-bottom() { $.position == bottom };
}

# vim: ft=perl6
