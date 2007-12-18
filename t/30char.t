#!perl -T

use strict;
use warnings;
use Test::More qw/ no_plan /;

use WebService::EveOnline;

my $API_KEY = $ENV{EVE_API_KEY} || 'abcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDEabcdeABCDE12345678900000';
my $USER_ID = $ENV{EVE_USER_ID} || 1000000;

SKIP: {
	skip "Please set environment variables EVE_API_KEY and EVE_USER_ID to run tests", 8 unless $USER_ID != 1000000;
	
	my $eve = WebService::EveOnline->new( { user_id => $USER_ID, api_key => $API_KEY } );
    my @c = $eve->characters;

	is( ref($c[0]), 'WebService::EveOnline', 'Returns a WebService::EveOnline object?' );
	like( $c[0]->character_id, qr/\d+/, 'Looks like a character id?' );
	like( $c[0]->account_balance, qr/\d+/, 'Looks like an account balance?' );
	like( $c[0]->character_race, qr/\w+/, 'Looks like a race?' );
	like( $c[0]->character_gender, qr/\w+/, 'Looks like a gender?' );
	like( $c[0]->character_bloodline, qr/\w+/, 'Looks like a bloodline?' );
	like( $c[0]->attributes->memory, qr/\d+/, 'Looks like an attribute?' );
    
    my @s = $c[0]->skills;
	
    like( $s[0]->skill_id, qr/\d+/, 'Looks like a skill?' );

	# this test fails if the current selected character has no skill currently training.
    # as such it is currently disabled.
    #like( $c[0]->skill_in_training->skill_id, qr/\d+/, 'Looks like a skill in training?' );
	
};
