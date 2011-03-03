use Test::More;

BEGIN { use_ok( 'WWW::3Taps::API::Types', qw/:all/ ) }

my @tests = (
  {
    name => 'Source',
    ok   => ['abc12'],
    fail => [qw/11 ab abcdefgh/]
  },
  {
    name => 'Category',
    ok   => [qw/FOOB FooB+OR+BarB FooB+OR+BARB+OR+BAzI/],
    fail => [qw/FOO+ FOOO+ FOoD+BARB+ FOo+BARB+ FOOB+OR+BaR+OR FOOO+OR+BARB+/]
  },
  {
    name => 'Location',
    ok   => [qw/FOO BAR/],
    fail => [qw/F B FO BA QUUX ZING/]
  },
  {
    name => 'Timestamp',
    ok   => [ '2001-02-02 20:00:01', '1998-05-05 17:22:10' ],
    fail =>
      [ '1970-02-31 12:00:00', '1999-xx-89 33:33:33', '22-22-22 90-01-01' ]
  },
  {
    name => 'JSONMap',
    ok   => [qw/{} {"foo":11}/],
    fail => [qw/{] 55 []/]
  },
  {
    name => 'Retvals',
    ok   => [qw/source,category heading,body,image/],
    fail => [qw/foo,bar,baz biz baz, body,image,foo/]
  },
  {
    name => 'Dimension',
    ok   => [qw(source category location)],
    fail => [qw(foo bar foo,bar)]
  },
  {
    name => 'List',
    ok   => [qw( foo foo,bar foo,bar,baz)],
    fail => [ 'foo,', 'foo bar' ],
  }

);

foreach my $type (@tests) {
  ok __PACKAGE__->can( $type->{name} ), "can $type->{name}";
  ok my $is_type = __PACKAGE__->can("is_$type->{name}"), "can is_$type->{name}";
  ok( $is_type->($_),  "$_ is $type->{name}" )   for ( @{ $type->{ok} } );
  ok( !$is_type->($_), "$_ isnt $type->{name}" ) for ( @{ $type->{fail} } );
}

done_testing;
