# $Id: Kit.pm,v 1.1.1.1 2006/03/27 00:49:39 gene Exp $

package SVG::Graph::Kit;
$VERSION = '0.00_1';
use strict;
use warnings;
use Carp;

use base qw( SVG::Graph );
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

sub new {
    my( $class, %args ) = @_;
    my $proto = ref( $class ) || $class;

    # Skim-off the glyph and data item layer.
    my @items = @{ $args{items} };
    delete $args{items};

    # Construct the SVG::Graph object with the remaining arguments.
    my $self = $class->SUPER::new( %args );
    bless $self, $class;

    # Proceed to the automatic metaglyphification.
    $self->_init( @items );

    return $self;
}

sub _init {
    my $self = shift;
    my $master_frame = $self->add_frame();
    for my $item ( @_ ) {  # For each LoH argument...
        my $frame = $master_frame->add_frame();
        # Add glyphs and data sets.
        while( my( $key, $val ) = each %$item ) {
            if( $key eq 'data' ) {
                $frame->add_data( dataset( $val ) );
            }
            else {
                $frame->add_glyph( $key, %$val );
            }
        }
    }
}

sub dataset {
    my $data = shift;

    my $dataset = [];

    for my $point ( @$data ) {
        # Handle arrays of arrays or numbers.
        if( ref $point eq 'ARRAY' || not(ref $point) ) {
            my $label = 'x';  # Datum labels go x, y, z.

            # Are we an array or a number?
            $point = ref $point eq 'ARRAY'
                ? { map { $label++ => $_ } @$point }
                : { $label => $point }
        }

        # Add out data point to the data set.
        push @$dataset, ref $point eq 'SVG::Graph::Data::Datum'
            ? $point : SVG::Graph::Data::Datum->new( %$point );
    }

    return SVG::Graph::Data->new( data => $dataset );
}

1;

__END__

=head1 NAME

SVG::Graph::Kit - Simplified data plotting

=head1 SYNOPSIS

  use SVG::Graph::Kit;
  my $r = shift || 50;
  my $m = shift || 20;
  my $i = 0;
  my $g = SVG::Graph::Kit->new(
    width => 600, height => 600, margin => 30,
    items => [
        { axis => { 'x_absolute_ticks' => 1, 'y_absolute_ticks' => 1,
                    'stroke' => 'black', 'stroke-width' => 2 },
        },
        { data => [ map { [ $i++, int(rand $r)] }
            qw(2 3 5 7 11 13 17 19 23 29 31 37 41) ],
          scatter => { fill => 'white', 'fill-opacity' => 1,
            stroke => 'blue' },
          line => { fill => 'yellow', 'fill-opacity' => 0.5,
            stroke => 'yellow' },
        },
        { data => [ map { [int(rand $r), int(rand $r)] } 0 .. $m ],
          bar => { fill => 'green', 'fill-opacity' => 0.5,
            stroke => 'green' },
        },
    ],
  );

  print $g->draw;

=head1 DESCRIPTION

An C<SVG::Graph::Kit> object is a simplified, restricted, automatic
data plotting tool that let's you plot data without needing to handle
nested frames or coordinate mapping.

=head1 PUBLIC METHODS

=head2 new

  my $obj = SVG::Graph::Kit->new(%arguments);

Return a new C<SVG::Graph::Kit> instance with any data or glyph
B<item>s automatically added to the plot.

The arguments can be any valid C<SVG::Graph> construction parameters,
like width and height, plus an B<item> list of data and glyphs.  The
glyphs are defined by C<SVG::Graph>.  The data can be a 1D list of
numbers, an array reference of 1, 2 or 3-D data points, a hash
reference with "x, y, z" keyed coordinates or a list of
C<SVG::Graph::Data::Datum> points.

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
