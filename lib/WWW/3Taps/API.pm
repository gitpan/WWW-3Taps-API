package WWW::3Taps::API;

use Moose;
use MooseX::Params::Validate;
use URI;
use LWP::UserAgent;
use JSON::Any;
use WWW::3Taps::API::Types
  qw( Source Category Location Timestamp JSONMap Retvals List Dimension);

=head1 NAME

WWW::3Taps::API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has _server => (
  is      => 'rw',
  isa     => 'Str',
  default => 'http://3taps.net'
);

has _ua => (
  is      => 'ro',
  isa     => 'LWP::UserAgent',
  default => sub { LWP::UserAgent->new() }
);

has _json_handler => (
  is      => 'rw',
  default => sub { JSON::Any->new( utf8 => 1, allow_nonref => 1 ) },
  handles => { _from_json => 'from_json' },
);

=head1 SYNOPSIS


  use WWW::3Taps::API;

  my $api = WWW::3Taps::API->new();
  my $results = $api->search( location => 'LAX+OR+NYC', category => 'VAUT' );
  my $count = $api->count( location => 'LAX+OR+NYC', category => 'VAUT' );


=head1 SUBROUTINES/METHODS

=head2 search(%params)

  my $api    = WWW::3Taps::API->new;
  my $result = $api->search(
    location    => 'LAX+OR+NYC',
    category    => 'VAUT',
    annotations => '{"make":"porsche"}'
  );

  # {
  #   execTimeMs => 7,
  #   numResults => 0,
  #   results    => [],
  #   success    => 1
  # }


The search method creates a new search request.

=head3 Parameters

=over

=item rpp


The number of results to return for a synchonous search. If this is not specified, 
a maximum of ten postings will be returned at once. If this is set to -1, all matching
postings will be returned at once. 

=item page

The page number of the results to return for a synchronous search, where zero is the 
first page of results. If this is not specified, the most recent page of postings will
be returned.

=item source

The 5-character source code a posting must have if is to be included in the list of 
search results.

=item category

The 4-character category code a posting must have if it is to be included in the list 
of search results. Note that multiple categories can be searched by passing in multiple
category codes, separated by +OR+.


=item location

The 3-character location code a posting must have if it is to be included in the list 
of search results. Note that multiple locations can be searched by passing in multiple 
location codes, separated by +OR+.


=item heading

A string which must occur within the heading of the posting if it is to be included in 
the list of search results.


=item body

A string which must occur within the body of the posting if it is to be included in the
list of search results.

=item text

A string which must occur in either the heading or the body of the posting if it is to 
be included in the list of search results.

=item poster

The user ID of the person who created the posts. If this is specified, only postings 
created by the specified user will be included in the list of search results

=item externalID

A string which must match the "externalID" field for a posting if it is to be included
in the list of search results.

=item start

(YYYY-MM-DD HH:MM:SS) This defines the desired starting timeframe for the search query.
Only postings with a timestamp greater than or equal to the given value will be
included in the list of search results. Note: all times in 3taps are in UTC.

=item end


(YYYY-MM-DD HH:MM:SS) This defines the desired ending timeframe for the search query. 
Only postings with a timestamp less than or equal to the given value will be included 
in the list of search results. Note: all times in 3taps are in UTC.

=item annotations

A JSON encoded map of key/value pairs that a posting must have in annotations to be 
included in the list of search results


=item trustedAnnotations

A JSON encoded map of key/value pairs that a posting must have in trusted annotations
to be included in the list of search results



=item retvals

A comma-separated list of the fields to return for each posting that matches the desired
set of search criteria. The following field names are currently supported:

  source
  category
  location
  longitude
  latitude
  heading
  body
  images
  externalURL
  userID
  timestamp
  externalID
  annotations
  postKey

These fields match the fields with the same name as defined in the Posting API.  If no 
retvals argument is supplied, the following list of fields will be returned by default:

  category
  location
  heading
  externalURL
  timestamp

=back

=head3 Returns

A hashref containing a decoded JSON object with the following fields:

=over

=item success

If the search was a success, this will be true.

=item numResults

The total number of results found for this search.

=item execTimeMs

The amount of time it took 3taps to perform your search, in milliseconds.

=item error

If success is false, error will contain the error message

=item results

An array of posting objects, each containing the fields specified in retvals

=back

=cut

my @_search_params = (
  rpp                => { isa => 'Int',     optional => 1 },
  page               => { isa => 'Int',     optional => 1 },
  source             => { isa => Source,    optional => 1 },
  category           => { isa => Category,  optional => 1 },
  location           => { isa => Location,  optional => 1 },
  heading            => { isa => 'Str',     optional => 1 },
  body               => { isa => 'Str',     optional => 1 },
  text               => { isa => 'Str',     optional => 1 },
  poster             => { isa => 'Str',     optional => 1 },
  externalID         => { isa => 'Str',     optional => 1 },
  start              => { isa => Timestamp, optional => 1 },
  end                => { isa => Timestamp, optional => 1 },
  annotations        => { isa => JSONMap,   optional => 1 },
  trustedAnnotations => { isa => JSONMap,   optional => 1 },
  retvals            => { isa => Retvals,   optional => 1 }
);

sub search {
  my ( $self, %params ) = validated_hash( \@_, @_search_params );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search');
  $uri->query_form(%params);

  return $self->_do_request($uri);
}

=head2 count(%search_params)

  my $api = WWW::3Taps::API->new;
  my $result = $api->count( location => 'LAX', category => 'VAUT' );

  # { count => 146725 }


Returns the number of items matching a given search. Note that this method accepts the
same general parameters as the search method.


=head3 Parameters

Same as C<search> method

=head3 Returns

A hashref with a single field, "count", holding the number of matches found for the 
given parameters.

=cut

sub count {
  my ( $self, %params ) = validated_hash(
    \@_, @_search_params
  );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search/count');
  $uri->query_form(%params);

  return $self->_do_request($uri);

}

=head2 best_match( $keyword )

  my $api = WWW::3Taps::API->new;
  my $result = $api->best_match('iPad');

  # { category => undef, numResults => 50483160 }


Returns the 3taps category associated with the keywords, along with the number of 
results for that category in 3taps.

=head3 Parameters

=over

=item keyword

One or more words to find the best match for.

=back

=head3 Returns

A hashref with two fields: category and numResults, containing the 3taps category code and number of results found.

=cut

sub best_match {
  my $self = shift;
  my ($keywords) = pos_validated_list( \@_, { isa => 'Str' }, );

  my $uri = URI->new( $self->_server );

  $uri->path('search/best-match');
  $uri->query_form( keywords => $keywords );

  return $self->_do_request($uri);
}

=head2 range(%search_params, fields => $fields)

  my $api = WWW::3Taps::API->new;
  my $result = $api->range( location => 'LAX', category => 'VAULT', fields => 'year,price');

  # {
  #   price => { max => 15000, min => 200 },
  #   year  => { max => 2011, min => 1967 },
  # }



Returns the minimum and maximum values currently in 3taps for the given fields, that 
match the given search parameters. The basic idea here is to provide developers with a
method of determining sensible values for range-based filters. Note that this method 
accepts the same query parameters as the search method.

=head3 Parameters

=over

=item fields

A comma-separated list of fields to retrieve the min and max values for. The Search API
will look for the min and max values in fields and annotations.

=back

=head3 Returns

A hashref with the min and max values for each field.

=cut

sub range {
  my ( $self, %params ) =
    validated_hash( \@_, @_search_params, fields => { isa => List } );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search/range');
  $uri->query_form(%params);

  return $self->_do_request($uri);
}

=head2 summary( %search_params, dimension => $dimension)


  my $api = WWW::3Taps::API->new;
  my $result = $api->summary( text => 'toyota', dimension => 'source');

  # {
  #   execTimeMs => 360,
  #   totals => {
  #     "37SIG" => 0,
  #     "3TAPS" => 0,
  #     "9-1-1" => 0,
  #     "AMZON" => 0,
  #     "CRAIG" => 184231,
  #     "E_BAY" => 5221,
  #      ...
  #   }
  # }

Returns the total number of postings found in 3taps, across the given dimension, that 
match the given search query parameters. For example, searching for "text=toyota" 
across "dimension=source" would return a list of all sources in 3taps, along with the 
number of postings matching the search "text=toyota" in that source. All search query 
parameters are supported. You may currently search across dimensions source, category, 
and location. At this time, category will only search across top level categories, and 
location is limited to our top 10 metro areas.

=head3 Parameters

=over

=item dimension

The dimension to summarize across: source, category, or location.

=back

=head3 Returns

A hashref with the following fields:

=over

=item totals

A decoded JSON object with one field for each member of the dimension, along with the 
total found (matching the search query) in that dimension.

=item execTimeMs

The number of milliseconds it took 3taps to retrieve this information for you. 

=back

=cut

sub summary {
  my ( $self, %params ) =
    validated_hash( \@_, @_search_params, dimension => { isa => Dimension } );

  confess 'You need to provide at least a query parameter'
    unless scalar values %params;

  my $uri = URI->new( $self->_server );

  $uri->path('search/summary');
  $uri->query_form(%params);

  return $self->_do_request($uri);
}

sub _do_request {
  my ( $self, $uri ) = @_;
  my $response = $self->_ua->get($uri);

  if ( $response->is_success ) {
    return $self->_from_json( $response->content );
  }
  else { confess $response->status_line; }

}

=head1 AUTHOR

Eden Cardim, C<< <edencardim at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-3taps-api at rt.cpan.org>, or 
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-3Taps-API>.
I will be notified, and then you'll automatically be notified of progress on your bug
as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::3Taps::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-3Taps-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-3Taps-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-3Taps-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-3Taps-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Eden Cardim

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
