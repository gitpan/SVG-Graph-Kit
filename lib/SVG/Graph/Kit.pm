# $Id: Kit.pm,v 1.8 2006/04/16 01:40:30 gene Exp $

package SVG::Graph::Kit;
$VERSION = '0.00_6';
use strict;
use warnings;
use Carp;

use base qw( SVG::Graph );
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

sub new {
    my( $class, %args ) = @_;
    my $proto = ref( $class ) || $class;

    # Strip-off the glyph and data item layers.
    my %kit = ();
    if( $args{_axis} ) {
        $kit{_axis} = $args{_axis};
        delete $args{_axis};
    }
    if( $args{_items} ) {
        $kit{_items} = $args{_items};
        delete $args{_items};
    }
    $args{width}  ||= 600;
    $args{height} ||= 600;
    $args{margin} ||= 35;

    # Construct the SVG::Graph object with the remaining arguments.
    my $self = $class->SUPER::new( %args );
    bless $self, $class;

    # Proceed to the automatic metaglyphification.
    $self->_init( %kit );

    return $self;
}

sub _init {
    my $self = shift;
    my %args = @_;

    if( $args{_axis} ) {
        my $xs = $args{_axis}->{xs} || $args{_axis}->{s} || 1;
        my $ys = $args{_axis}->{ys} || $args{_axis}->{s} || 1;

        my $x = $args{_axis}->{x} || 0;
        my $xlabels ||= $args{_axis}->{xlabels};
        unless( $xlabels ) {
            for( my $i = 0; $i <= $x; $i += $xs )
                { push @$xlabels, $i; }
        }
        my $xsize = @$xlabels - 1;

        my $y = $args{_axis}->{y} || 0;
        my $ylabels ||= $args{_axis}->{ylabels};
        unless( $ylabels ) {
            for( my $i = 0; $i <= $y; $i += $ys )
                { push @$ylabels, $i; }
        }
        my $ysize = @$ylabels - 1;

        my $grid = 'palegray';
        my $line = { stroke => $grid };

        unshift @{ $args{_items} },
            { axis => {
                x_absolute_ticks => $xs,
                x_tick_labels => $xlabels,
                y_absolute_ticks => $ys,
                y_tick_labels => $ylabels,
                stroke => $grid, },
            },
            { data => [ [0, 0], [$x, $y] ], line => $line },
            # XXX Use grid=>0 unless the plot has <=50 ticks.
            ( !$args{_axis}->{grid} ? () : (
                ( map { {
                    data => [ [$_ * $xs, 0], [$_ * $xs, $y] ], line => $line
                } } 1 .. $xsize ),
                ( map { {
                    data => [ [0, $_ * $ys], [$x, $_ * $ys] ], line => $line
                } } 1 .. $ysize ))
            );
#use Data::Dumper;die Dumper($args{_items}[0]);
    }

    # Give unto us a frame!
    my $master_frame = $self->add_frame();
    # Each item is a hashref with data or presentation info.
    for my $item ( @{ $args{_items} } ) {
        # I never do nuthin' wrong but I always get the blame.
        my $frame = $master_frame->add_frame();
        while( my( $key, $val ) = each %$item ) {
            if( $key eq 'data' ) {
                # Make sure that the data is a proper data set first.
                $frame->add_data( dataset( $val ) );
            }
            else {
                # Assume that the value is a proper CSS hashref.
                $frame->add_glyph( $key, %$val );
            }
        }
    }
}

sub dataset {
    my $data = shift;

    return $data if ref($data) eq 'SVG::Graph::Data';

    my $dataset = [];

    for my $datum ( @$data ) {
        $datum = [ $datum ] unless ref $datum;
        if( ref($datum) eq 'ARRAY' ) {
            my $x = 'x';
            $datum = { map { $x++ => $_ } @$datum };
        }
        if( ref($datum) eq 'HASH' ) {
            $datum = SVG::Graph::Data::Datum->new( %$datum )
        }
        push @$dataset, $datum;
    }

    return SVG::Graph::Data->new( data => $dataset );
}

1;

__END__

=head1 NAME

SVG::Graph::Kit - Simplified data plotting

=head1 SYNOPSIS

  use SVG::Graph::Kit;

  my @x = qw(2 3 5 7 11 13 17 19 23 29 31 37 41);
  my $x = @x;
  my $y = $x[-1];
  my $i = 0;
  my $d = [ map { [ ++$i, $_ ] } @x ];
  my @items = (
    { data => $d, line => { stroke => 'yellow' } },
    { data => $d, scatter => { stroke => 'blue' } },
  );

  # Explicitly declared SVG::Graph axis.
  my $g = SVG::Graph::Kit->new(
    _items => [ {
            axis => {
                x_fractional_ticks => $x,
                y_absolute_ticks => 1,
                stroke => 'palegray', # etc.
            },
            data => [ [0, 0], [$x, $y] ],
            line => { stroke => 'palegray' },
        },
        @items,
    ],
  );

  # Absolute x and y ticks on an auto-axis.  Use grid=>0 for large x*y.
  $g = SVG::Graph::Kit->new(
    _axis => { grid => 1, y => $y, x => $x },
    _items => $items,
  );

  # Ticks and grid lines at a locked-step factor apart.
  $g = SVG::Graph::Kit->new(
    _axis => { grid => 1, x => $x, y => $y, s => 2 },
    _items => $items,
  );

  # Ticks and grid lines at different step factors apart.
  $g = SVG::Graph::Kit->new(
    _axis => { grid => 1,
        x => $x, y => $y,
        xs => 2, ys => 5,
    },
    _items => $items,
  );

  # Scale the x and y ticks.  Use this technique for large data sets.
  $g = SVG::Graph::Kit->new(
    _axis => { grid => 1,
        x => $x, y => $y,
        xs => int $x / 10,
        ys => int $y / 10,
    },
    _items => $items,
  );

  # Scale the y ticks to fit x (yeilding decimal y tick lables).
  my $s = $y / $x;
  $g = SVG::Graph::Kit->new(
    _axis => { grid => 1,
        x => $x, y => $y,
        ys => $s,
        ylabels => [ map { sprintf '%.2f', $_ * $s } 0 .. $x ],
    },
    _items => $items,
  );

  print $g->draw;

=head1 DESCRIPTION

An C<SVG::Graph::Kit> object is a simplified, automated tool that
allows data plotting without requiring any knowledge of the
C<SVG::Graph> API.

=head1 PUBLIC METHODS

=head2 new

  my $obj = SVG::Graph::Kit->new(%arguments);

Return a new C<SVG::Graph::Kit> instance with any given data or glyphs
automatically added to the plot.

This method can be called with any valid C<SVG::Graph> construction
parameters (e.g. width, height, margin) plus an B<_items> list of
things to show - data and glyphs.  The glyphs are defined by
C<SVG::Graph> and the actual data can be either a 1-D list of numbers,
an array reference of 1, 2 or 3-D data points, a hash reference with
"x, y, z" keyed coordinates, a list of C<SVG::Graph::Data::Datum>
points or a C<SVG::Graph::Data> object.

An axis must be specified for this module to display any data.
This can be done by adding standard C<SVG::Graph> axis items or by
providing an B<_axis> hash reference.  This feature is under
developement.  Please see the C<eg/normalize-primes> program for a
working example.

=head1 SEE ALSO

L<SVG::Graph>

=head1 COPYRIGHT

Copyright 2006, Gene Boggs, All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL 
licenses, any version.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=cut
