#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';#tests => 1;

use lib 'lib';
use_ok 'SVG::Graph::Kit';

TODO: {
    local $TODO = "SVG::Graph fails without constructor arguments";
    my $g = eval { SVG::Graph::Kit->new };
#    warn $@ if $@;
    isa_ok $g, 'SVG::Graph::Kit';
}

my $i = 0;
my %args = (
    width => 600, height => 600, margin => 30,
    items => [
        { axis => { 'x_absolute_ticks' => 1, 'y_absolute_ticks' => 1,
                    'stroke' => 'black', 'stroke-width' => 2 },
        },
        { data => [ map { [ $i++, int(rand 50)] }
            qw(2 3 5 7 11 13 17 19 23 29 31 37 41) ],
          scatter => { fill => 'white', 'fill-opacity' => 1,
            stroke => 'blue' },
          line => { fill => 'yellow', 'fill-opacity' => 0.5,
            stroke => 'yellow' },
        },
        { data => [ map { [int(rand 50), int(rand 50)] } 0 .. 20 ],
          bar => { fill => 'green', 'fill-opacity' => 0.5,
            stroke => 'green' },
        },
    ],
);

__END__
my $g = eval { SVG::Graph::Kit->new(%args) };
print $g->draw;
warn $@ if $@;
isa_ok $g, 'SVG::Graph::Kit';
local $/;
my $svg = 't/SVG-Graph-Kit.svg';
open SVG, $svg or die "Can't read $svg";
$svg = <SVG>;
close SVG;
is $svg, $g->draw, 'draw';
