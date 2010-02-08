#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'SVG::Graph::Kit',
    VERSION_FROM => 'lib/SVG/Graph/Kit.pm',
    PREREQ_PM => { 'SVG::Graph' => 0 },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/SVG/Graph/Kit.pm',
           AUTHOR => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
