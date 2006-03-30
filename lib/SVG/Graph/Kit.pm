# $Id: Kit.pm,v 1.2 2006/03/30 04:38:48 gene Exp $

package SVG::Graph::Kit;
$VERSION = '0.00_2';
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
    # Give unto us a frame!
    my $master_frame = $self->add_frame();
    # Each item is a hashref with data or presentation info.
    for my $item ( @_ ) {
        # I never do nuthin' wrong but I always get the blame.
        my $frame = $master_frame->add_frame();
        while( my( $key, $val ) = each %$item ) {
            if( $key eq 'data' ) {
                # Make sure that the data is a proper dataset.
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
  my @x = qw( 2 3 5 7 11 13 17 19 23 29 31 37 41 );
  my $i = 0;
  while( (my $p = <>) =~ s/\D//g && ++$i <= $max ) {
     push @x, $p;
  }
  $i = 0;
  my $g = SVG::Graph::Kit->new(
     width => 600, height => 600, margin => 30,
     items => [
        { axis => { 'x_absolute_ticks' => 1, 'y_absolute_ticks' => 1,
                    'stroke' => 'gray', },
          data => [ [0,0], [ $x[-1], $x[-1] ] ],
          line => { stroke => 'gray' },
        },
        { data => [ map { [ ++$i, $_ ] } @x ],
          line => { stroke => 'yellow' },
          scatter => { stroke => 'blue' },
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
reference with "x, y, z" keyed coordinates, a list of
C<SVG::Graph::Data::Datum> points or a C<SVG::Graph::Data> object.

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
