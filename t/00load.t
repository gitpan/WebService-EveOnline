#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'WebService::EveOnline' );
    use_ok( 'WebService::EveOnline::Cache' );
}
