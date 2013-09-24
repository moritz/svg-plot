class SVG::Plot::Data::Series;

has @.keys handles   (add_to_keys   => 'push', key_elems   => 'elems');
has @.values handles (add_to_values => 'push', value_elems => 'elems');

has $!range;

multi method new(*@args, *%named is copy) {
    if @args && @args.grep(Pair) == @args {
        my @a = @args.sort: *.key;
        %named<keys>   = @a>>.key;
        %named<values> = @a>>.value;
    }
    my $new = self.bless(|%named);
    return $new;
}

method !build_range {
    die "A series must have values before it can be plotted"
        unless @.values;
    # TODO: should be SVG::Plot::Data::Range instead
    return (@.values.min .. @.values.max);
}

method range() {
    $!range = self!build_range() unless defined $!range;
    $!range;
}

method add_kv($k, $v) {
    $.add_to_keys($k);
    $.add_to_values($v);
}

method add_pair(Pair $p ($key, $value)) {
    $.add_to_keys($key);
    $.add_to_values($value);
}

method prepare() {
    die "Series key/value count don't match: $.key_elems != $.value_elems"
        unless $.key_elems == $.value_elems;

    1;
}


# vim: ft=perl6
