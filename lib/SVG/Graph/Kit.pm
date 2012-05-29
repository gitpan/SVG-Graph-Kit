package SVG::Graph::Kit;
# ABSTRACT: Simplified data plotting with SVG

use strict;
use warnings;

our $VERSION = '0.0301';

use base qw(SVG::Graph);
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;

=head1 SYNOPSIS

  use SVG::Graph::Kit;
  my $data = [ [ 1,  2, 0 ],
               [ 2,  3, 1 ],
               [ 3,  5, 1 ],
               [ 4,  7, 2 ],
               [ 5, 11, 3 ],
               [ 6, 13, 5 ], ];
  my $g = SVG::Graph::Kit->new(data => $data);
  print $g->draw;
  my $n;
  for my $dim (qw(x y z)) {
    for my $stat (qw(min max mean mode median range stdv percentile)) {
      $n = $stat eq 'percentile' ? 90 : undef; # Inspect the 90th percentile.
      printf "%s %s = %0.2f\n", $dim, $stat, $g->stat($dim, $stat, $n);
    }
  }

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
        threshold => $max_axis_data, # default: 30
    },
  );

Return a new C<SVG::Graph::Kit> instance.

Optional arguments:

  data => Numeric vectors (the datapoints)
  plot => Chart type and data rendering properties
  axis => Axis rendering properties or 0 for off

Except for the C<plot type>, C<axis =E<gt> 0> and C<axis threshold>,
the C<plot> and C<axis> arguments are ordinary CSS, 'a la
C<SVG::Graph>.

The C<plot type> is given in C<SVG::Graph>.  C<axis =E<gt> 0> turns
off the rendering of the axis.  The C<axis threshold> represents
the number of labeled tick marks displayed on a scaled graph.

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

    # Start with an initial frame...
    my $frame = $self->add_frame;

    # Plot the data.
    if ($args{data}) {
        # Load the graph data and use the SVG::Graph::Data object for label making.
        $self->{graph_data} = _load_data($args{data}, $frame);
        # Add the data to the graph.
        my %plot = (
            stroke         => $args{plot}{stroke}         || 'red',
            fill           => $args{plot}{fill}           || 'red',
            'fill-opacity' => $args{plot}{'fill-opacity'} || 0.5,
        );
        $args{plot}{type} ||= 'scatter';
        $frame->add_glyph($args{plot}{type}, %plot);
    }

    # Handle the axis unless it's set to 0.
    if (not(exists $args{axis}) or exists $args{axis} and $args{axis}) {
        my %axis = $self->_load_axis($args{data}, $args{axis});
        $frame->add_glyph('axis', %axis);
    }
}

sub _load_axis {
    my($self, $data, $axis) = @_;

    # Initialize an empty axis unless given a hashref.
    $axis = {} if not ref $axis eq 'HASH';

    # Set the default properties and user override.
    my %axis = (
        x_intercept => 0,
        y_intercept => 0,
        stroke => 'gray',
        'stroke-width' => 2,
        threshold => 30, # Max data per axis
        %$axis, # User override
    );
# TODO Note in POD that threshold => 0 means "do not scale."

    # Compute scale factors.
    my ($xscale, $yscale) = (1, 1);
    if ($data and $axis{threshold} and ($self->{graph_data}->xmax - $self->{graph_data}->xmin) > $axis{threshold}) {
        # Round to the integer, i.e. 0 decimal places.
        $xscale = sprintf '%.0f', $self->{graph_data}->xmax / $axis{threshold};
    }
    if ($data and $axis{threshold} and $self->{graph_data}->ymax - $self->{graph_data}->ymin > $axis{threshold}) {
        # Round to the integer, i.e. 0 decimal places.
        $yscale = sprintf '%.0f', $self->{graph_data}->ymax / $axis{threshold};
    }

    # Use absolute_ticks if no tick mark setting is provided.
    unless (defined $axis{x_absolute_ticks} or defined $axis{x_fractional_ticks}) {
        $axis{x_absolute_ticks} = $xscale;
    }
    unless (defined $axis{y_absolute_ticks} or defined $axis{y_fractional_ticks}) {
        $axis{y_absolute_ticks} = $yscale;
    }

    # Use increments of 1 to data-max for ticks if none are provided.
    if ($data and !defined $axis{x_tick_labels} and !defined $axis{x_intertick_labels}) {
        if ($xscale > 1) {
            $axis{x_tick_labels} = [ $self->{graph_data}->xmin ];
            push @{ $axis{x_tick_labels} }, $_ * $xscale for 1 .. $axis{threshold};
        }
        else {
            $axis{x_tick_labels} = [ $self->{graph_data}->xmin .. $self->{graph_data}->xmax ];
        }
    }
    if ($data and !defined $axis{y_tick_labels} and !defined $axis{y_intertick_labels}) {
        if ($yscale > 1) {
            $axis{y_tick_labels} = [ $self->{graph_data}->ymin ];
            push @{ $axis{y_tick_labels} }, $_ * $yscale for 1 .. $axis{threshold};
        }
        else {
            $axis{y_tick_labels} = [ $self->{graph_data}->ymin .. $self->{graph_data}->ymax ];
        }
    }

    # Remove keys not used by parent module.
    delete $axis{threshold};

    return %axis;
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

=head2 stat()

  $g->stat($dimension, $name);
  $g->stat('x', 'mean');
  $g->stat('y', 'stdv');
  $g->stat('z', 'percentile');
  # etc.

This method is a direct call to the appropriate C<SVG::Graph::Data>
"x-method" (i.e. min, max, mean, mode, median, range, stdv and
percentile).

=cut


sub stat {
    my ($self, $dimension, $name, @args) = @_;
    my $method = $dimension . $name;
    return $self->{graph_data}->$method(@args);
}

1;
__END__

=head1 TO DO

Allow log scaling.

Position axis orgin.

Call any C<Statistics::Descriptive> method, not just those given by
C<SVG::Graph>.

=head1 SEE ALSO

* The code in F<t/*>.

* L<SVG::Graph>

=head1 COPYRIGHT

Copyright Gene Boggs, All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL 
licenses, any version.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=cut
