package WebService::EveOnline;

use strict;
use warnings;

use base qw/ WebService::EveOnline::Base /;

our $VERSION = '0.03';
our $AGENT = 'WebService::EveOnline';
our $EVE_API = "http://api.eve-online.com/";
our $DEBUG_MODE = $ENV{EVE_DEBUG_ON} || undef;

=head1 NAME

WebService::EveOnline -- a wrapper intended to (eventually) provide a 
consistent interface to the MMORPG game, "Eve Online"

(N.B. Export EVE_USER_ID and EVE_API_KEY to your environment before installing 
to run all tests.) 

Running under MS Windows will not work without tweaking. Support for non-unix architectures
is intended to follow at a later date. Please consider this module's status as
EXPERIMENTAL.

=head1 VERSION

0.03 - This is an incomplete implementation of the Eve Online API, but is a starting point.

=head1 SYNOPSIS

	use WebService::EveOnline;
	
	my $eve = WebService::EveOnline->new({
		user_id => <user_id>,
		api_key => '<api_key>'
	});
	
	my $character = $eve->character->name('<character_name>');
	
	print $character->training->{name} . " will finish training at " .
	 $character->training->{training_end} . "\n";

=head1 DESCRIPTION

WebService::EveOnline (essentially) presents a nice programatic sugar over the
top of the pretty cronky API that CCP games provide. The idea is that an 
interested party (e.g. me) can keep track of what's going on with my characters
in a similar manner to what EveMON does.

There is currently no item data provided with this interface (although the API 
exposes no item data anyway, it'd be nice to have at some point).

Also, no map or wallet information is supported although this will be added as
a priority over the coming weeks.

=cut

=head2 Initialising

WebService::EveOnline is instantiated with a 'standard' (so much as these 
things are) call to "new". Usually, at this point you would pass down a
hashref that contained the keys "user_id" and "api_key" as demonstrated in the
synopsis.

You MUST specify your user_id and api_key parameters in order to get the API to
work, even if you're only interested in returning data where they are not 
normally required by the API.

You may also specify the following parameters:

cache_type: Defaults to 'SQLite'. For now, please keep the default.
cache_dbname: Database to use to store cached skill data.
cache_user: Username of the database to use. Do not use yet.
cache_pass: Password of the database to use. Do not use yet.
cache_init: Set this to 'no' to disable caching. Not recommended.
cache_maxage: Maximum time (in seconds) to wait before a cache rebuild.

Currently, only SQLite databases are supported. Using another database should
be fairly straightforward to add in, but isn't available yet.

You can specify ":memory" as the cache_dbname to build the cache in memory if
required.

=head1 API

API reference as follows:

=cut

=head2 new
   
Set up the initial object by calling the new method on it. It is important to
pass a valid user id and api key (available from http://api.eve-online.com/)
or this module will not do anything useful. That is does anything useful at
all is debatable, but it does let me print out my favourite character's account
balance, so that's pretty much all I want/need it to do at the moment... :-)

    my $eve = WebService::EveOnline->new({
		user_id => <user_id>,
		api_key => '<api_key>'
	});

=cut

sub new {
	my ($class, $params) = @_;

    unless (ref($params) eq "HASH" && $params->{user_id} && $params->{api_key}) {
	    die("Cannot instantiate without a user_id/api_key!\nPlease visit $EVE_API if you still need to get one.");
    }

	return bless(WebService::EveOnline::Base->new($params), $class);
}


=head1 BUGS

If you don't happen to have my specific user_id and api_key, you milage may 
*seriously* vary. I've not been playing Eve Online all that long, and there 
are probably dozens of edge cases I need to look at and resolve.

Contributions/patches/suggestions are all gratefully received.

Please report any bugs or feature requests to C<bug-webservice-eveonline at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-EveOnline>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 MOTIVATION

Frankly, whilst the Eve Online API is better than nothing, it's pretty horrible
to work with. I wanted to concentrate on my code rather than parsing results, so
I decided to hide the gory details away in a nice module I didn't have to look at
much. Having said that, by no means is this code considered anything other than a
quick and dirty hack that does precisely the job I want it to do (and no more).

=head1 AUTHOR

Chris Carline, C<< <chris at carline.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Chris Carline, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
