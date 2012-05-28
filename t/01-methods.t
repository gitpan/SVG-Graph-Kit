#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('SVG::Graph::Kit') }

my $g = eval { SVG::Graph::Kit->new };
isa_ok $g, 'SVG::Graph::Kit', 'no arguments';

my $data = [ [ 1,  2,  0,  0.0],
             [ 2,  3,  1,  0.1],
             [ 3,  5,  1,  0.2],
             [ 4,  7,  2,  0.4],
             [ 5, 11,  3,  0.8],
             [ 6, 13,  5,  1.6],
             [ 7, 17,  8,  3.2],
             [ 8, 19, 13,  6.4],
             [ 9, 23, 21, 12.8],
             [10, 29, 34, 25.6] ];
$g = SVG::Graph::Kit->new(data => $data);
#$g = SVG::Graph::Kit->new(data => $data, axis => 0);
#$g = SVG::Graph::Kit->new(data => $data, axis => 1);
#$g = SVG::Graph::Kit->new(data => $data, axis => { stroke => 'blue' });
isa_ok $g, 'SVG::Graph::Kit';

my $x = eval { $g->draw };
ok !$@, 'draw';
__END__
# DEBUG:
my $output = "$0.svg";
if ($output =~ /^([\/\w .-]+)$/) {
    $output = $1;
}
else {
    die "Disallowed characters in filename: '$output'";
}
open my $fh, '>', $output or die "Can't write to $output: $!\n";
print $fh $x, "\n";
