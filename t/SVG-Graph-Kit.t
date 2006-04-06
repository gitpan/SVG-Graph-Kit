#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan'; #tests => 4;
use_ok 'SVG::Graph::Kit';
my $g = eval { SVG::Graph::Kit->new };
warn $@ if $@;
isa_ok $g, 'SVG::Graph::Kit', 'Without arguments';
__END__
my $i = 0;
my @x = qw(2 3 5 7 11 13 17 19 23 29 31 37 41);
my $data = [ map { [ ++$i, $_ ] } @x ];
$i = 0;
my %args = ( _autoaxis => { m => @x, n => $x[-1], s => @x } );
$g = eval { SVG::Graph::Kit->new(%args) };
warn $@ if $@;
isa_ok $g, 'SVG::Graph::Kit', 'With arguments';
# XXX This is one lame test:
ok $g->draw, 'Can draw';
