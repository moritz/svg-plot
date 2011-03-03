BEGIN { @*INC.push: 'lib' };
use SVG::Plot::Data::Series;
use Test;
plan *;

ok my $s = SVG::Plot::Data::Series.new(), 'empty constructor is OK';
dies_ok { $s.range() }, 'range of empty series is not OK';
$s.add_kv(1, 2);
$s.add_kv(2, 5);
is $s.range.min, 2, '.range.min works';
is $s.range.max, 5, '.range.max works';

$s.add_to_values: 4;
is $s.values.join(','), '2,5,4', 'can add to values, and preserve order';
dies_ok { $s.prepare }, 'cannot prepare with keys.elems != values.elemens';
$s.add_to_keys: 3;
lives_ok { $s.prepare }, 'can prepare when counts are equal';
is ~$s.keys, '1 2 3', 'can obtain keys';

done;
