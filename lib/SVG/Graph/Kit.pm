package SVG::Graph::Kit;
# ABSTRACT: Simplified data plotting with SVG

use strict;
use warnings;

our $VERSION = '0.0101';

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
  my $g = SVG::Graph::Kit->new(data => $data);
  print $g->draw;

=head1 DESCRIPTION

An C<SVG::Graph::Kit> object is an automated data plotter that is a
subclass of C<SVG::Graph>.

=head1 METHODS

=head2 new()

  $g = SVG::Graph::Kit->new(%arguments);
  $g = SVG::Graph::Kit->new();
  $g = SVG::Graph::Kit->new(data => \@numeric);
  $g = SVG::Graph::Kit->new(data => \@numeric, axis => 0);
  # Custom:
  $g = SVG::Graph::Kit->new(
    width => 300, height => 300, margin => 20,
    data => [[0,0], [1,1]],
    plot => {
      type => 'line', # default: scatter
      'fill-opacity' => 0.5, # etc.
    },
    axis => {
        'stroke-width' => 2, # etc.
    },
  );

Return a new C<SVG::Graph::Kit> instance.

Optional arguments:

  data => Numeric vectors (the datapoints)
  plot => Chart type and data rendering properties
  axis => Axis rendering properties or 0 for off

Except for the C<plot type>, the C<plot> and non-0 C<axis> arguments
are ordinary CSS, 'a la C<SVG::Graph>.

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

    # The SVG::Graph::Data object for use in label making.
    my $graph_data;

    # Start with an initial frame...
    my $frame = $self->add_frame;

    # Plot the data.
    if ($args{data}) {
        # Load the graph data.
        $graph_data = _load_data($args{data}, $frame);
        # Add the data to the graph.
        my %plot = (
            stroke         => $args{plot}{stroke}         || 'red',
            fill           => $args{plot}{fill}           || 'red',
            'fill-opacity' => $args{plot}{'fill-opacity'} || 0.5,
        );
        $args{plot}{type} ||= 'scatter';
        $frame->add_glyph($args{plot}{type}, %plot);
    }

    # Handle the axis.
    if (not(exists $args{axis})                # There is no axis argument
        or exists $args{axis} and $args{axis}  # Or there is one and it's true
    ) {
        # Initialize an empty axis unless given a hashref
        $args{axis} = {} if not ref $args{axis} eq 'HASH';

        # Set the default properties and user override.
        my %axis = (
            stroke => 'gray',
            'stroke-width' => 2,
            %{ $args{axis} }, # User override
        );
        unless (defined $axis{x_absolute_ticks} or defined $axis{x_fractional_ticks}) {
            $axis{x_absolute_ticks} = 1;
        }
        unless (defined $axis{y_absolute_ticks} or defined $axis{y_fractional_ticks}) {
            $axis{y_absolute_ticks} = 1;
        }
        if ($args{data} and !defined $axis{x_tick_labels}) {
            $axis{x_tick_labels} = [ $graph_data->xmin .. $graph_data->xmax ];
        }
        if ($args{data} and !defined $axis{y_tick_labels}) {
            $axis{y_tick_labels} = [ $graph_data->ymin .. $graph_data->ymax ];
        }

       # Add the axis to the graph.
        $frame->add_glyph('axis', %axis);
    }
}

sub _load_data {
    my ($data, $frame) = @_;
    # Create individual data points.
    my @data = ();
    for my $datum (@$data) {
        # Add our 3D data point.
        push @data, SVG::Graph::Data::Datum->new(
            x => $datum->[0],
            y => $datum->[1],
            z => $datum->[2],
        );
    }
    # Instantiate a new SVG::Graph::Data object;
    my $obj = SVG::Graph::Data->new(data => \@data);
    # Populate our graph with data.
    $frame->add_data($obj);
    return $obj;
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
