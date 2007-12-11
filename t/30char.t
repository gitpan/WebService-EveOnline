#!perl -T

use strict;
use warnings;
use Test::More qw/ no_plan /;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

SKIP: {
	skip "Please set environment variables EVE_API_KEY and EVE_USER_ID to run tests", 9 unless $USER_ID != 1000000;
	
	my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );
			
	is( ref($eve->characters), 'WebService::EveOnline', 'Returns a WebService::EveOnline object?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->character_id, qr/\d+/, 'Looks like a character id?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->account_balance, qr/\d+/, 'Looks like an account balance?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->race, qr/\w+/, 'Looks like a race?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->gender, qr/\w+/, 'Looks like a gender?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->bloodline, qr/\w+/, 'Looks like a bloodline?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->attributes->{memory}, qr/\d+/, 'Looks like an attribute?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->skills->{rowset}->{row}->[0]->{typeID}, qr/\d+/, 'Looks like a skill?' );
	like( $eve->character->name($eve->characters->[0]->{_name})->training->{skillInTraining}, qr/\d+/, 'Looks like a skill in training?' );
	
};
