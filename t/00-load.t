#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';
BEGIN { use_ok( 'SVG::Graph::Kit' ) }
diag(sprintf 'Testing SVG::Graph::Kit %s, Perl %s, %s with SVG::Graph version %s',
    $SVG::Graph::Kit::VERSION, $], $^X, $SVG::Graph::VERSION
);
