package SVG::Graph::Kit;
# ABSTRACT: Simplified data plotting with SVG

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(SVG::Graph);
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

=head1 SYNOPSIS

  use SVG::Graph::Kit;
  my $data = [ [ 1,  2, 0, 0.0, 1 ],
               [ 2,  3, 1, 0.1, 4 ],
               [ 3,  5, 1, 0.2, 1 ],
               [ 4,  7, 2, 0.4, 5 ],
               [ 5, 11, 3, 0.8, 9 ],
               [ 6, 13, 5, 1.6, 2 ], ];
  my $g = SVG::Graph::Kit->new(
    data => $data,
    plot => {
      type => 'bezier',
      'fill-opacity' => 0.5, # etc.
    },
    axis => {
        'stroke-width' => 2,
        stroke => 'gray', # etc.
    },
  );

=head1 DESCRIPTION

An C<SVG::Graph::Kit> object is a simplified, automated tool that
allows data plotting without requiring any knowledge of the
C<SVG::Graph> API.

=head1 METHODS

=head2 new()

  my $obj = SVG::Graph::Kit->new(%arguments);

Return a new C<SVG::Graph::Kit> instance with any given data or glyphs
automatically added to the plot.

Where the arguments may be any of:

  data => Numeric vectors (the datapoints)
  plot => Chart type and data rendering properties
  axis => Axis rendering properties

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Move non-parent arguments to the kit.
    my %kit = ();
    for my $arg (qw(axis data plot)) {
        next unless exists $args{$arg};
        $kit{$arg} = $args{$arg};
        delete $args{$arg};
    }

    # Construct the SVG::Graph object with the remaining arguments.
    $args{width}  ||= 600;
    $args{height} ||= 600;
    $args{margin} ||= 35;
    my $self = $class->SUPER::new(%args);

    # Re-bless as a Graph::Kit object.
    bless $self, $class;
    $self->_setup(%kit);
    return $self;
}

sub _setup {
    my $self = shift;
    my %args = @_;

    my %label = ( x => [], y => [], z => [] );

    # Start with an initial frame...
    my $frame = $self->add_frame;

    # Handle the data.
    if ($args{data}) {
        # Create individual data points.
        my @data = ();
        for my $datum (@{ $args{data} }) {
            # Find the minimum and maximum labels.
            $label{x}[0] = $datum->[0] if not defined $label{x}[0] or $datum->[0] < $label{x}[0];
            $label{x}[1] = $datum->[0] if not defined $label{x}[1] or $datum->[0] > $label{x}[1];
            $label{y}[0] = $datum->[1] if not defined $label{y}[0] or $datum->[1] < $label{y}[0];
            $label{y}[1] = $datum->[1] if not defined $label{y}[1] or $datum->[1] > $label{y}[1];
            $label{z}[0] = $datum->[2] if not defined $label{z}[0] or $datum->[2] < $label{z}[0];
            $label{z}[1] = $datum->[2] if not defined $label{z}[1] or $datum->[2] > $label{z}[1];

            push @data, SVG::Graph::Data::Datum->new(
                x => $datum->[0],
                y => $datum->[1],
                z => $datum->[2],
            );
        }
        # Populate our graph with data.
        my $data = SVG::Graph::Data->new(data => \@data);
        $frame->add_data($data);
        my %plot = (
            stroke         => $args{plot}{stroke}         || 'red',
            fill           => $args{plot}{fill}           || 'red',
            'fill-opacity' => $args{plot}{'fill-opacity'} || 0.5,
        );
        # Add the data to the graph.
        $args{plot}{type} ||= 'scatter';
        $frame->add_glyph($args{plot}{type}, %plot);
    }

    # Handle the axis.
    if (not(exists $args{axis})                # There is no axis argument
        or exists $args{axis} and $args{axis}  # Or there is one and it's true
    ) {
        # Initialize an empty axis unless given a hashref
        $args{axis} = {} if not ref $args{axis} eq 'HASH';
        # Make tick labels.
        # Set the default properties and user override.
        my %axis = (
            x_absolute_ticks => 1,
            x_tick_labels    => [ $label{x}[0] .. $label{x}[1] ],
            y_absolute_ticks => 1,
            y_tick_labels    => [ $label{y}[0] .. $label{y}[1] ],
            z_absolute_ticks => 1,
            z_tick_labels    => [ $label{z}[0] .. $label{z}[1] ],
            stroke           => 'gray',
            'stroke-width'   => 2,
            %{ $args{axis} },
        );
       # Add the axis to the graph.
        $frame->add_glyph('axis', %axis);
    }
}

1;
__END__

=head1 TO DO

Scale axes.

Position axis orgin.

=head1 SEE ALSO

* The code in the F<eg/> and F<t/> directories.

* L<SVG::Graph>

=head1 COPYRIGHT

Copyright Gene Boggs, All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL 
licenses, any version.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=cut
