use Test::More;
use Test::Exception;
use HTTP::Response;

use Data::Dump;

BEGIN { use_ok('WWW::3Taps::API'); }

sub _build_response_ok {
  my $content = shift;
  my $res = HTTP::Response->new( 200, 'OK' );
  $res->content($content);
  return $res;
}

sub _build_response_err {
  my $res = HTTP::Response->new( 404, 'Not Found' );
  $res->content('ERROR');
  return $res;
}

my $three_tap = WWW::3Taps::API->new;
ok( $three_tap, 'ok' );

$three_tap->_ua->add_handler(
  request_send => sub { return _build_response_ok('{}') } );

ok( $three_tap->search( location => 'LAX+OR+NYC', category => 'VAUT' ),
  'search' );

ok( $three_tap->count( location => 'LAX', category => 'VAUT' ), 'count' );
ok( $three_tap->best_match('iPad'), 'best match' );

ok(
  $three_tap->range(
    location    => 'LAX',
    category    => 'VAUT',
    annotations => '{"make":"porsche"}',
    fields      => 'year,price'
  ),
  'range'
);

ok( $three_tap->summary( text => 'toyota', dimension => 'source' ), 'summary' );

$three_tap->_ua->remove_handler('request_send');
$three_tap->_ua->add_handler(
  request_send => sub { return _build_response_ok('{invalid \json ]00*d>:)') }
);

dies_ok { $three_tap->search( location => 'LAX+OR+NYC', category => 'VAUT' ) }
'search fails ok on bad json';

dies_ok { $three_tap->count( location => 'LAX', category => 'VAUT' ) }
'count dies ok on bad json';
dies_ok { $three_tap->best_match('iPad') } 'best-match dies ok on bad json';

$three_tap->_ua->remove_handler('request_send');
$three_tap->_ua->add_handler(
  request_send => sub { return _build_response_err() } );

dies_ok { $three_tap->search( location => 'LAX+OR+NYC', category => 'VAUT' ) }
'search fails ok on response fail';

dies_ok { $three_tap->count( location => 'LAX', category => 'VAUT' ) }
'count dies ok on response fail';
dies_ok { $three_tap->best_match('iPad') }
'best-match dies ok on response fail';

done_testing;
