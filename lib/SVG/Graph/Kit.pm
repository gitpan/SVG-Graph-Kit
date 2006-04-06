# $Id: Kit.pm,v 1.5 2006/04/06 03:31:51 gene Exp $

package SVG::Graph::Kit;
$VERSION = '0.00_4';
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
    if( $args{_autoaxis} ) {
        $kit{_autoaxis} = $args{_autoaxis};
        delete $args{_autoaxis};
        $args{width}  ||= 600;
        $args{height} ||= 600;
        $args{margin} ||= 35;
    }
    if( $args{_items} ) {
        $kit{_items} = $args{_items};
        delete $args{_items};
    }

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

    if( $args{_autoaxis} ) {
        my $x = $args{_autoaxis}->{x};
        my $y = $args{_autoaxis}->{y};
        my $s = $args{_autoaxis}->{s} || 1;

        # The scaled magnitude.
        $x ||= (int $args{_autoaxis}->{m} / $args{_autoaxis}->{s}) || 1;
        # Largest data-point.
        $y ||= $args{_autoaxis}->{n} || 1;

        my $labels = [ map { $_ * $x } 0 .. $y ];
        my $grid = 'palegray';
        my $line = { stroke => $grid, fill => $grid, 'fill-opacity' => 0.5, };

        unshift @{ $args{_items} },
            # Create an axis.
            { axis => {
                #x_intercept => 100, y_intercept => 100,
                x_absolute_ticks => $x, y_absolute_ticks => $x,
                x_tick_labels => $labels, y_tick_labels => $labels,
                stroke => $grid,
              },
            },
            # Create the reference lines.
            { data => [ [ 0, 0 ], [ $y, $y ] ],
              line => $line,
            },
            ( map { {
                data => [ [ 0, $_ * $x ], [ $y, $_ * $x ] ],
                line => $line,
              } } 1 .. $y / $x ),
            ( map { {
                data => [ [ $_ * $x, 0 ], [ $_ * $x, $y ] ],
                line => $line,
              } } 1 .. $y / $x );
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
  my $i = 0;
  my $data = [ map { [ ++$i, $_ ] } @x ];
  my $g = SVG::Graph::Kit->new(
    _autoaxis => { m => @x, n => $x[-1], s => @x, },
    _items => [
        { data => $data, line => { stroke => 'yellow'}, },
        { data => $data, scatter => { stroke => 'blue' }, },
    ],
  );
  print $g->draw;

=head1 DESCRIPTION

An C<SVG::Graph::Kit> object is a simplified, automated tool that
allows data plotting without requiring knowledge of the C<SVG::Graph>
API.

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

If this method is invoked with the optional B<_autoaxis> parameter,
an axis with scaled labels and grid-lines is automatically added to
the graph.  This parameter should be a hash reference having keys
B<m>, B<n> and B<s> that are used as the number of ticks plotted and
the largest tick desired and the scaling factor, respectively.

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
